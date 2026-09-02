import json
import math
from pathlib import Path
import sys

import mujoco
import numpy as np


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src"))

from build_model import build


def test_generated_models_start_hanging_with_direct_sensor_interface() -> None:
    for name, pole_count in (("single", 1), ("double", 2), ("triple", 3)):
        build(name)
        model = mujoco.MjModel.from_xml_path(str(ROOT / "src" / name / "model.xml"))
        config = json.loads((ROOT / "src" / name / "base_model.json").read_text())

        expected_qpos = np.array(
            [config["initial"]["cart_position"], math.pi, *([0.0] * (pole_count - 1))]
        )
        np.testing.assert_allclose(model.qpos0, expected_qpos, atol=1e-12)
        assert not np.any(model.jnt_limited[1:])
        assert model.ncam == 0

        expected_sensors = [
            "cart_position",
            *(f"pole{index}_relative_angle" for index in range(1, pole_count + 1)),
            "cart_velocity",
            *(f"pole{index}_relative_velocity" for index in range(1, pole_count + 1)),
        ]
        assert [model.sensor(index).name for index in range(model.nsensor)] == expected_sensors

        data = mujoco.MjData(model)
        mujoco.mj_forward(model, data)
        expected_sensor_state = np.concatenate((expected_qpos, np.zeros(pole_count + 1)))
        np.testing.assert_allclose(data.sensordata, expected_sensor_state, atol=1e-12)


def test_hanging_pose_places_every_tip_below_its_hinge() -> None:
    for name, pole_count in (("single", 1), ("double", 2), ("triple", 3)):
        build(name)
        model = mujoco.MjModel.from_xml_path(str(ROOT / "src" / name / "model.xml"))
        data = mujoco.MjData(model)
        mujoco.mj_forward(model, data)

        for index in range(1, pole_count + 1):
            prefix = "pole" if pole_count == 1 else f"pole{index}"
            hinge_z = data.site(prefix + "_hinge_site").xpos[2]
            tip_z = data.site(prefix + "_tip_site").xpos[2]
            assert tip_z < hinge_z
