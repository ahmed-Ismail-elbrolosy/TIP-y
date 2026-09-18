import ast
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
NOTEBOOK_MODELS = {
    "single/qlearning/train.ipynb": "single",
    "single/dqn/train.ipynb": "single",
    "single/actor_critic/train.ipynb": "single",
    "single/classical/swingup_pid_lqr.ipynb": "single",
    "double/dqn/train.ipynb": "double",
    "double/ppo/train_ppo.ipynb": "double",
}
NEURAL_NOTEBOOKS = {
    "single/dqn/train.ipynb",
    "single/actor_critic/train.ipynb",
    "double/dqn/train.ipynb",
}


def notebook_source(relative_path: str) -> str:
    notebook = json.loads((ROOT / relative_path).read_text())
    assert notebook["nbformat"] == 4
    return "\n".join(
        "".join(cell["source"])
        for cell in notebook["cells"]
        if cell["cell_type"] == "code"
    )


def notebook(relative_path: str) -> dict:
    return json.loads((ROOT / relative_path).read_text())


def embedded_model_xml(source: str) -> str:
    for node in ast.walk(ast.parse(source)):
        if not isinstance(node, ast.Assign) or len(node.targets) != 1:
            continue
        target = node.targets[0]
        if isinstance(target, ast.Name) and target.id == "MODEL_XML":
            value = ast.literal_eval(node.value)
            assert isinstance(value, str)
            return value
    raise AssertionError("MODEL_XML assignment not found")


def test_notebooks_embed_their_canonical_model() -> None:
    for notebook_path, model_name in NOTEBOOK_MODELS.items():
        expected = (ROOT / "models" / f"{model_name}.xml").read_text().strip()
        assert embedded_model_xml(notebook_source(notebook_path)).strip() == expected


def test_all_notebook_replays_use_the_canonical_camera() -> None:
    for notebook_path in NOTEBOOK_MODELS:
        assert 'camera="replay"' in notebook_source(notebook_path)


def test_all_double_pendulum_notebooks_use_a_100_newton_force_limit() -> None:
    for notebook_path in (
        "double/dqn/train.ipynb",
        "double/ppo/train_ppo.ipynb",
        "double/ppo/train_ppo_mjx_gpu.ipynb",
        "double/ppo/Copy of train_ppo_mjx_gpu_working.ipynb",
    ):
        source = notebook_source(notebook_path)
        assert "ACTION_LIMIT = 100.0" in source
        assert 'ctrlrange="-100 100" forcerange="-100 100"' in source
        assert "MAX_EPISODE_STEPS = 5000" in source
    for notebook_path in (
        "double/dqn/train.ipynb",
        "double/ppo/train_ppo.ipynb",
    ):
        source = notebook_source(notebook_path)
        assert "self.rail_limit, self.dt, self.current_step = 2.0" in source
        assert "reward -= 100.0" in source
    for notebook_path in (
        "double/ppo/train_ppo_mjx_gpu.ipynb",
        "double/ppo/Copy of train_ppo_mjx_gpu_working.ipynb",
    ):
        source = notebook_source(notebook_path)
        assert "RAIL_LIMIT = 2.0" in source
        assert "reward - jnp.where(terminated, 100.0, 0.0)" in source
        assert "-20 N" not in source
        assert "+20 N" not in source


def test_triple_mjx_ppo_notebook_has_three_link_task_contract() -> None:
    source = notebook_source("triple/ppo/train_ppo_mjx_gpu.ipynb")
    assert 'model="cartpole_triple"' in source
    assert "OBS_DIM = 11" in source
    assert "ACTION_DIM = 1" in source
    assert "ACTION_LIMIT = 100.0" in source
    assert "RAIL_LIMIT = 2.0" in source
    assert "MAX_EPISODE_STEPS = 5000" in source
    assert 'ctrlrange="-100 100" forcerange="-100 100"' in source
    assert 'name="pole3_hinge"' in source
    assert 'name="replay"' in source
    assert "mjx.put_model" in source


def test_triple_mjx_ppo_notebook_matches_double_notebook_structure() -> None:
    double_cells = notebook("double/ppo/Copy of train_ppo_mjx_gpu_working.ipynb")["cells"]
    triple_cells = notebook("triple/ppo/train_ppo_mjx_gpu.ipynb")["cells"]
    assert [cell["cell_type"] for cell in triple_cells] == [
        cell["cell_type"] for cell in double_cells
    ]

    source = notebook_source("triple/ppo/train_ppo_mjx_gpu.ipynb")
    for required in (
        "save_checkpoint",
        "restore_checkpoint",
        "collect_rollout",
        "append_metric",
        "dashboard.png",
        "run_eval",
        "replay.mp4",
        "mujoco.Renderer",
    ):
        assert required in source


def test_mjx_ppo_notebooks_use_the_mirrored_replay_camera() -> None:
    expected_camera = (
        '<camera name="replay" pos="0 6 1.4" fovy="50"\n'
        '            xyaxes="-1 0 0 0 -0.15 0.988686" />'
    )
    for notebook_path in (
        "double/ppo/train_ppo_mjx_gpu.ipynb",
        "double/ppo/Copy of train_ppo_mjx_gpu_working.ipynb",
    ):
        assert expected_camera in notebook_source(notebook_path)


def test_neural_notebooks_require_and_report_a_jax_gpu() -> None:
    for notebook_path in NEURAL_NOTEBOOKS:
        source = notebook_source(notebook_path)
        assert '"jax[cuda12]"' in source
        assert 'platform != "gpu"' in source
        assert "GPU accelerator required" in source
        assert "jax.default_backend()" in source
