import logging
import re
from typing import List, Dict, Any

logger = logging.getLogger(__name__)

TECH_ALIASES = {
    "react.js": "react", "reactjs": "react",
    "react native": "react-native", "rn": "react-native",
    "node.js": "node", "nodejs": "node",
    "vue.js": "vue", "vuejs": "vue",
    "next.js": "next", "nextjs": "next",
    "nuxt.js": "nuxt", "nuxtjs": "nuxt",
    "typescript": "ts", "javascript": "js",
    "postgresql": "postgres", "mongodb": "mongo",
    "kubernetes": "k8s", "dart": "flutter",
}

def _normalize(skill: str) -> str:
    s = skill.lower().strip()
    return TECH_ALIASES.get(s, s)

def calculate_match_score(
    dev_skills: List[str],
    dev_seniority: str,
    project_tech_stack: List[str],
    project_description: str = ""
) -> float:
    dev_skills_norm   = {_normalize(s) for s in dev_skills}
    proj_stack_norm   = [_normalize(s) for s in project_tech_stack]
    proj_stack_norm   = list(dict.fromkeys(proj_stack_norm))  # ✅ FIX: remove duplicates
    description_lower = project_description.lower()

    if not proj_stack_norm and not description_lower:
        return 10.0

    # 1. Stack Coverage (60%)
    matched        = sum(1 for tech in proj_stack_norm if tech in dev_skills_norm)
    total          = len(proj_stack_norm) if proj_stack_norm else 1
    stack_score    = (matched / total) * 60.0

    # 2. Primary Tech Bonus (20%)
    primary_bonus  = 20.0 if proj_stack_norm and proj_stack_norm[0] in dev_skills_norm else 0.0

    # 3. Description Keyword Boost (up to 10) — only if stack coverage is weak
    desc_bonus = 0.0
    if description_lower and stack_score < 30:
        keyword_hits = sum(
            1 for skill in dev_skills_norm
            if re.search(rf'\b{re.escape(skill)}\b', description_lower)
        )
        desc_bonus = min(10.0, keyword_hits * 3.0)

    # 4. Seniority Bonus (up to 20%)
    seniority_lower = dev_seniority.lower()
    if "lead"   in seniority_lower: seniority_bonus = 20.0
    elif "senior" in seniority_lower: seniority_bonus = 12.0
    elif "mid"    in seniority_lower: seniority_bonus = 6.0
    else:                             seniority_bonus = 0.0

    final_score = stack_score + primary_bonus + desc_bonus + seniority_bonus
    final_score = max(5.0, min(100.0, final_score))

    logger.info(f"Score: stack={stack_score:.1f} + primary={primary_bonus} + desc={desc_bonus:.1f} + seniority={seniority_bonus} = {final_score:.1f}")
    return round(final_score, 1)

def batch_calculate_matches(
    dev_skills: List[str],
    dev_seniority: str,
    projects: List[Dict[str, Any]]
) -> List[Dict[str, Any]]:
    return [
        {"projectId": proj.get('id'), "score": calculate_match_score(
            dev_skills, dev_seniority,
            proj.get('techStack', []),
            proj.get('description', "")
        )}
        for proj in projects
    ]