from pathlib import Path
import time

import mujoco
import mujoco.viewer

model = mujoco.MjModel.from_xml_path(
    str(Path(__file__).resolve().parents[1] / "models" / "double_pole.xml")
)
data = mujoco.MjData(model)

with mujoco.viewer.launch_passive(model, data) as viewer:
    while viewer.is_running():
        step_start = time.time()
        mujoco.mj_step(model, data)
        viewer.sync()
        time.sleep(max(0, model.opt.timestep - (time.time() - step_start)))
