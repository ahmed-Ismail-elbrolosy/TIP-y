"""Compare analytical triple-pendulum accelerations with MuJoCo."""

import json
from pathlib import Path
import sys

import mujoco
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from build_model import build


HERE = Path(__file__).resolve().parent
CONFIG = json.loads((HERE / "base_model.json").read_text())
MC = float(CONFIG["cart"]["mass"])
DC = float(CONFIG["cart"]["damping"])
G = float(CONFIG["gravity"])
M = np.asarray(CONFIG["links"]["mass"], dtype=float)
L = np.asarray(CONFIG["links"]["length"], dtype=float)
WIDTH = np.asarray(CONFIG["links"]["width"], dtype=float)
C = L / 2
IYY = M * (WIDTH**2 + L**2) / 12
D = np.asarray(CONFIG["links"]["damping"], dtype=float)
FORCE_LIMIT = float(CONFIG["actuator"]["force_limit"])


def mass_matrix(phi: np.ndarray) -> np.ndarray:
    p1, p2, p3 = phi
    m1, m2, m3 = M
    l1, l2, _ = L
    c1, c2, c3 = C
    i1, i2, i3 = IYY
    return np.array(
        [
            [MC + M.sum(), -(c1*m1 + l1*(m2+m3))*np.cos(p1),
             -(c2*m2 + l2*m3)*np.cos(p2), -c3*m3*np.cos(p3)],
            [-(c1*m1 + l1*(m2+m3))*np.cos(p1), i1+c1**2*m1+l1**2*(m2+m3),
             l1*(c2*m2+l2*m3)*np.cos(p1-p2), c3*l1*m3*np.cos(p1-p3)],
            [-(c2*m2 + l2*m3)*np.cos(p2),
             l1*(c2*m2+l2*m3)*np.cos(p1-p2), i2+c2**2*m2+l2**2*m3,
             c3*l2*m3*np.cos(p2-p3)],
            [-c3*m3*np.cos(p3), c3*l1*m3*np.cos(p1-p3),
             c3*l2*m3*np.cos(p2-p3), i3+c3**2*m3],
        ]
    )


def bias_forces(phi: np.ndarray, velocity: np.ndarray) -> np.ndarray:
    p1, p2, p3 = phi
    dx, d1, d2, d3 = velocity
    m1, m2, m3 = M
    l1, l2, _ = L
    c1, c2, c3 = C
    j1, j2, j3 = D
    return np.array(
        [
            DC*dx + (c1*m1+l1*(m2+m3))*d1**2*np.sin(p1)
            + (c2*m2+l2*m3)*d2**2*np.sin(p2) + c3*m3*d3**2*np.sin(p3),
            -(c1*m1+l1*(m2+m3))*G*np.sin(p1)
            + l1*(c2*m2+l2*m3)*d2**2*np.sin(p1-p2)
            + c3*l1*m3*d3**2*np.sin(p1-p3)
            + (j1+j2)*d1-j2*d2,
            -(c2*m2+l2*m3)*G*np.sin(p2)
            - l1*(c2*m2+l2*m3)*d1**2*np.sin(p1-p2)
            + c3*l2*m3*d3**2*np.sin(p2-p3)
            - j2*d1+(j2+j3)*d2-j3*d3,
            -c3*m3*G*np.sin(p3)
            - c3*l1*m3*d1**2*np.sin(p1-p3)
            - c3*l2*m3*d2**2*np.sin(p2-p3)
            - j3*d2+j3*d3,
        ]
    )


def analytical_acceleration(state: np.ndarray, force: float) -> np.ndarray:
    rhs = np.array([force, 0.0, 0.0, 0.0])
    return np.linalg.solve(
        mass_matrix(state[1:4]), rhs - bias_forces(state[1:4], state[4:8])
    )


def to_mujoco(state: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    x, p1, p2, p3, dx, d1, d2, d3 = state
    return (
        np.array([x, p1, p2-p1, p3-p2]),
        np.array([dx, d1, d2-d1, d3-d2]),
    )


def from_mujoco_acceleration(qacc: np.ndarray) -> np.ndarray:
    return np.array([
        qacc[0],
        qacc[1],
        qacc[1] + qacc[2],
        qacc[1] + qacc[2] + qacc[3],
    ])


def main() -> None:
    build("triple")
    model_path = HERE / "model.xml"
    model = mujoco.MjModel.from_xml_path(str(model_path))
    data = mujoco.MjData(model)
    rng = np.random.default_rng(20260830)
    worst = 0.0
    for _ in range(50):
        state = np.concatenate([
            rng.uniform([-0.5, -0.4, -0.4, -0.4], [0.5, 0.4, 0.4, 0.4]),
            rng.uniform(-1.0, 1.0, 4),
        ])
        force = float(rng.uniform(-0.5 * FORCE_LIMIT, 0.5 * FORCE_LIMIT))
        data.qpos[:], data.qvel[:] = to_mujoco(state)
        data.ctrl[0] = force
        mujoco.mj_forward(model, data)
        actual = from_mujoco_acceleration(data.qacc)
        expected = analytical_acceleration(state, force)
        worst = max(worst, float(np.max(np.abs(actual - expected))))
    print(f"maximum acceleration error over 50 states: {worst:.3e}")
    if worst > 2e-4:
        raise SystemExit("MuJoCo and analytical dynamics do not match")


if __name__ == "__main__":
    main()
