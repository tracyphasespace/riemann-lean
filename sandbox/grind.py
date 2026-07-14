import os
import subprocess
import sys
import requests

# CONFIGURATION
LOOGLE_API = "https://loogle.lean-lang.org/json"

class GrindColors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'

def ensure_sandbox_path(filepath: str) -> None:
    norm = os.path.abspath(filepath)
    if f"{os.sep}sandbox{os.sep}" not in norm:
        print(f"{GrindColors.FAIL}Refusing to run: target is not in /sandbox/.{GrindColors.ENDC}")
        sys.exit(1)

def find_anchors(lines, kinds):
    anchors = []
    for i, line in enumerate(lines):
        for k in kinds:
            if line.lstrip().startswith(k + " "):
                anchors.append(i)
                break
    return anchors

def get_lean_goal(lines, line_num):
    for i in range(line_num, -1, -1):
        if ":" in lines[i] and any(lines[i].lstrip().startswith(k + " ") for k in ["theorem", "lemma", "axiom"]):
            return lines[i].strip()
    return "Goal state unavailable (Parser could not find theorem header)"

def query_loogle(query_text):
    if ":" in query_text:
        query_text = query_text.split(":")[-1]
    if "->" in query_text:
        query_text = query_text.split("->")[-1]
    params = {'q': query_text.strip()}
    try:
        response = requests.get(LOOGLE_API, params=params, timeout=5)
        if response.status_code == 200:
            hits = response.json().get("hits", [])
            return [h["name"] for h in hits[:5]]
    except Exception:
        pass
    return []

def inject_proposal(filepath, line_num, proof_text):
    with open(filepath, 'r') as f:
        lines = f.readlines()

    target_line = lines[line_num]
    if "axiom" not in target_line:
        print(f"{GrindColors.FAIL}Error: Line {line_num+1} is not an axiom.{GrindColors.ENDC}")
        return False

    # Insert a comment with the proposed proof on the next line.
    indent = "".join([c for c in target_line if c.isspace()])
    proposal = f"{indent}-- proposed: {proof_text}\n"
    lines.insert(line_num + 1, proposal)

    with open(filepath, 'w') as f:
        f.writelines(lines)
    return True

def grind_file(filepath, no_build=True, include_axioms=True):
    ensure_sandbox_path(filepath)
    print(f"{GrindColors.HEADER}🔨 Grinding File: {filepath}{GrindColors.ENDC}")

    with open(filepath, 'r') as f:
        lines = f.readlines()

    anchors = []
    if include_axioms:
        anchors = find_anchors(lines, ["axiom", "theorem", "lemma"])
    else:
        anchors = [i for i, line in enumerate(lines) if "sorry" in line]

    if not anchors:
        print(f"{GrindColors.OKGREEN}No targets found.{GrindColors.ENDC}")
        return

    print(f"Found {len(anchors)} targets to review.")

    for i, line_num in enumerate(anchors):
        line_text = lines[line_num].strip()
        print(f"\n{GrindColors.HEADER}--- Target {i+1}/{len(anchors)} (Line {line_num+1}) ---{GrindColors.ENDC}")
        print(f"Context: {line_text}")

        goal = get_lean_goal(lines, line_num)
        print(f"{GrindColors.OKBLUE}🔭 Scout (Loogle) searching for: {goal}...{GrindColors.ENDC}")
        hints = query_loogle(goal)
        print(f"   Hints found: {hints}")

        print(f"\n{GrindColors.WARNING}👷 Architect Needed!{GrindColors.ENDC}")
        print("Paste the Goal and Hints into your AI Chat. Copy the 'by ...' block back here.")
        candidate = input(f"{GrindColors.OKGREEN}Enter Tactic Block (e.g., 'simp [add_comm]'): {GrindColors.ENDC}")

        subprocess.run(["cp", filepath, f"{filepath}.bak"], check=False)
        ok = inject_proposal(filepath, line_num, candidate)
        if not ok:
            subprocess.run(["mv", f"{filepath}.bak", filepath], check=False)
            continue

        print(f"{GrindColors.OKGREEN}✅ Proposal recorded (no-build mode).{GrindColors.ENDC}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 grind.py <path_to_lean_file> [--no-build] [--axioms]")
        sys.exit(1)
    target = sys.argv[1]
    include_axioms = "--axioms" in sys.argv[2:]
    grind_file(target, no_build=True, include_axioms=include_axioms)
