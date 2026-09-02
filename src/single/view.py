from pathlib import Path
import sys
import time

import mujoco
import mujoco.viewer

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from build_model import build

build("single")
model_path = Path(__file__).with_name("model.xml")
model = mujoco.MjModel.from_xml_path(str(model_path))
data = mujoco.MjData(model)

with mujoco.viewer.launch_passive(model, data) as viewer:
    while viewer.is_running():
        step_start = time.time()
        mujoco.mj_step(model, data)
        viewer.sync()
        time.sleep(max(0, model.opt.timestep - (time.time() - step_start)))
