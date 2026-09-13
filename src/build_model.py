"""Regenerate MuJoCo XML files from each model's base_model.json."""

import argparse
import json
import math
from pathlib import Path
import xml.etree.ElementTree as ET


SRC = Path(__file__).resolve().parent
MODEL_NAMES = ("single", "double", "triple")


def vector(values: list[float]) -> str:
    return " ".join(f"{value:.12g}" for value in values)


def ensure_inertial(body: ET.Element) -> ET.Element:
    inertial = body.find("inertial")
    if inertial is None:
        inertial = ET.Element("inertial")
        joint_count = len(body.findall("joint"))
        body.insert(joint_count, inertial)
    return inertial


def ensure_named_child(parent: ET.Element, tag: str, name: str) -> ET.Element:
    child = parent.find(f"{tag}[@name='{name}']")
    if child is None:
        child = ET.SubElement(parent, tag, name=name)
    return child


def build(name: str) -> None:
    model_dir = SRC / name
    config = json.loads((model_dir / "base_model.json").read_text())
    model_path = model_dir / "model.xml"
    tree = ET.parse(model_path)
    root = tree.getroot()

    masses = config["links"]["mass"]
    lengths = config["links"]["length"]
    widths = config["links"]["width"]
    depths = config["links"]["depth"]
    damping = config["links"]["damping"]
    friction = config["links"]["friction_loss"]
    initial_angles = config["initial"]["angles"]
    count = len(masses)
    arrays = (lengths, widths, depths, damping, friction)
    if (
        count != len(config["target"]["angles"])
        or count != len(initial_angles)
        or any(len(v) != count for v in arrays)
    ):
        raise ValueError(
            f"{name}: all link, initial, and target arrays must have {count} entries"
        )
    if float(config["initial"]["cart_position"]) != 0.0:
        raise ValueError(f"{name}: nonzero initial cart position is not supported")

    compiler = root.find("compiler")
    if compiler is None:
        compiler = ET.Element("compiler")
        root.insert(0, compiler)
    compiler.set("angle", "radian")
    compiler.set("autolimits", "true")
    compiler.set("inertiafromgeom", "false")

    option = root.find("option")
    if option is None:
        option = ET.SubElement(root, "option")
    option.set("timestep", f"{config['timestep']:.12g}")
    option.set("gravity", f"0 0 {-float(config['gravity']):.12g}")
    option.set("integrator", "RK4")

    worldbody = root.find("worldbody")
    if worldbody is None:
        raise ValueError(f"{name}: worldbody is missing")
    if name in ("single", "double"):
        asset = root.find("asset")
        if asset is None:
            asset = ET.Element("asset")
            worldbody_index = next(
                (index for index, child in enumerate(root) if child.tag == "worldbody"),
                len(root),
            )
            root.insert(worldbody_index, asset)
        ensure_named_child(asset, "material", "rail_limit_mat").set(
            "rgba", "0.95 0.55 0.05 1"
        )

        replay_camera = ensure_named_child(worldbody, "camera", "replay")
        replay_camera.attrib.update(
            pos="0 -6 1.4",
            fovy="50",
            xyaxes="1 0 0 0 0.15 0.988686",
        )

        frame = worldbody.find("body[@name='frame']")
        if frame is None:
            raise ValueError(f"{name}: frame body is missing")
        rail_limit = float(config["cart"]["rail_limit"])
        rail = ensure_named_child(frame, "geom", "rail")
        rail.attrib.update(
            type="box",
            pos="0 0 0.85",
            size=vector([rail_limit, 0.05, 0.05]),
            material="metal_mat",
        )
        for side, position in (("left", -rail_limit), ("right", rail_limit)):
            stop = ensure_named_child(frame, "geom", f"rail_limit_{side}")
            stop.attrib.update(
                type="box",
                pos=vector([position, 0.0, 0.95]),
                size="0.025 0.12 0.1",
                material="rail_limit_mat",
            )

    cart = root.find("./worldbody/body[@name='cart']")
    if cart is None:
        raise ValueError(f"{name}: cart body is missing")
    cart_joint = cart.find("joint[@name='cart_slide']")
    if cart_joint is None:
        raise ValueError(f"{name}: cart_slide joint is missing")
    cart_joint.set(
        "range",
        vector([-config["cart"]["rail_limit"], config["cart"]["rail_limit"]]),
    )
    cart_joint.set("damping", f"{config['cart']['damping']:.12g}")
    cart_joint.set("frictionloss", f"{config['cart']['friction_loss']:.12g}")
    cart_inertial = ensure_inertial(cart)
    cart_inertial.attrib.update(
        pos="0 0 0", mass=f"{config['cart']['mass']:.12g}",
        diaginertia="0.0333 0.0333 0.0333"
    )

    for index in range(count):
        body_name = "pole" if count == 1 else f"pole{index + 1}"
        body = root.find(f".//body[@name='{body_name}']")
        if body is None:
            raise ValueError(f"{name}: {body_name} body is missing")
        if index > 0:
            body.set("pos", vector([0.0, 0.03, lengths[index - 1]]))

        hinge_name = "pole_hinge" if count == 1 else f"pole{index + 1}_hinge"
        hinge = body.find(f"joint[@name='{hinge_name}']")
        if hinge is None:
            raise ValueError(f"{name}: {hinge_name} joint is missing")
        relative_angle = initial_angles[index] - (
            initial_angles[index - 1] if index else 0.0
        )
        half_angle = relative_angle / 2
        body.set(
            "quat",
            vector([math.cos(half_angle), 0.0, -math.sin(half_angle), 0.0]),
        )
        hinge.set("axis", "0 -1 0")
        hinge.set("ref", f"{relative_angle:.17g}")
        hinge.set("limited", "false")
        hinge.attrib.pop("range", None)
        hinge.set("damping", f"{damping[index]:.12g}")
        hinge.set("frictionloss", f"{friction[index]:.12g}")

        mass = masses[index]
        length = lengths[index]
        width = widths[index]
        depth = depths[index]
        com = length / 2
        inertia = [
            mass * (depth**2 + length**2) / 12,
            mass * (width**2 + length**2) / 12,
            mass * (width**2 + depth**2) / 12,
        ]
        ensure_inertial(body).attrib.update(
            pos=vector([0.0, 0.0, com]),
            mass=f"{mass:.12g}",
            diaginertia=vector(inertia),
        )

        geom_name = "pole_geom" if count == 1 else f"pole{index + 1}_geom"
        geom = body.find(f"geom[@name='{geom_name}']")
        if geom is None:
            raise ValueError(f"{name}: {geom_name} geometry is missing")
        geom.set("pos", vector([0.0, 0.0, com]))
        geom.set("size", vector([width / 2, depth / 2, length / 2]))
        geom.set("mass", f"{mass:.12g}")

        tip_name = "pole_tip_site" if count == 1 else f"pole{index + 1}_tip_site"
        tip = body.find(f"site[@name='{tip_name}']")
        if tip is None:
            raise ValueError(f"{name}: {tip_name} site is missing")
        tip.set("pos", vector([0.0, 0.0, length]))

        mount = body.find(f"geom[@name='pole{index + 2}_mount_pin']")
        if mount is not None:
            mount_position = mount.get("pos")
            if mount_position is None:
                raise ValueError(
                    f"{name}: pole{index + 2}_mount_pin position is missing"
                )
            old = [float(value) for value in mount_position.split()]
            old[2] = length
            mount.set("pos", vector(old))

    sensor = root.find("sensor")
    if sensor is None:
        sensor = ET.Element("sensor")
        actuator_index = next(
            (index for index, child in enumerate(root) if child.tag == "actuator"),
            len(root),
        )
        root.insert(actuator_index, sensor)
    sensor.clear()
    ET.SubElement(sensor, "jointpos", name="cart_position", joint="cart_slide")
    for index in range(count):
        hinge_name = "pole_hinge" if count == 1 else f"pole{index + 1}_hinge"
        ET.SubElement(
            sensor,
            "jointpos",
            name=f"pole{index + 1}_relative_angle",
            joint=hinge_name,
        )
    ET.SubElement(sensor, "jointvel", name="cart_velocity", joint="cart_slide")
    for index in range(count):
        hinge_name = "pole_hinge" if count == 1 else f"pole{index + 1}_hinge"
        ET.SubElement(
            sensor,
            "jointvel",
            name=f"pole{index + 1}_relative_velocity",
            joint=hinge_name,
        )

    actuator = root.find("actuator")
    if actuator is None:
        actuator = ET.SubElement(root, "actuator")
    actuator.clear()
    limit = config["actuator"]["force_limit"]
    ET.SubElement(
        actuator,
        "motor",
        name="cart_motor",
        joint="cart_slide",
        gear="1",
        ctrlrange=vector([-limit, limit]),
        forcerange=vector([-limit, limit]),
    )

    ET.indent(tree, space="  ")
    tree.write(model_path, encoding="unicode")
    print(f"updated {model_path.relative_to(SRC.parent)}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("model", choices=(*MODEL_NAMES, "all"), default="all", nargs="?")
    args = parser.parse_args()
    names = MODEL_NAMES if args.model == "all" else (args.model,)
    for name in names:
        build(name)


if __name__ == "__main__":
    main()
