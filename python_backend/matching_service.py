import logging
from typing import List, Dict, Any

logger = logging.getLogger(__name__)

def calculate_match_score(dev_skills: List[str], dev_seniority: str, project_tech_stack: List[str], project_description: str = "") -> float:
    """
    Calculates a 'real' match score between a developer and a project.
    """
    # Standardize all to lowercase for better matching
    dev_skills_set = {s.lower() for s in dev_skills}
    proj_stack_lower = [s.lower() for s in project_tech_stack]
    description_lower = project_description.lower()
    
    logger.info(f"Matching: DevSkills={dev_skills_set}, Seniority={dev_seniority}, ProjStack={proj_stack_lower}")
    
    match_count = 0
    primary_matched = False
    
    # Check if we have tags, else try to infer from description
    if not proj_stack_lower and not description_lower:
        logger.warning("Project tech stack and description are empty!")
        return 10.0

    # 1. Primary Tag Check
    if proj_stack_lower:
        primary_tech = proj_stack_lower[0]
        if primary_tech in dev_skills_set:
            primary_matched = True
            
        for tech in proj_stack_lower:
            if tech in dev_skills_set:
                match_count += 1
    
    # 2. Fuzzy Description Check (Fallback or Boost)
    keyword_match_count = 0
    if description_lower:
        for skill in dev_skills_set:
            # Check if skill name exists as a standalone word/token in description
            # Simple check for now, can be improved with regex
            if f" {skill} " in f" {description_lower} " or f" {skill}," in f" {description_lower} " or description_lower.startswith(f"{skill} "):
                keyword_match_count += 1
                if not primary_matched and match_count == 0:
                   # If no tags matched but a skill is in the description, treat it as a weak match
                   match_count += 0.5 

    logger.info(f"Match results: Primary={primary_matched}, MatchCount={match_count}, Keywords={keyword_match_count}")
    
    # Calculation
    if primary_matched:
        # Start at 90 for primary match
        base_score = 90.0
    elif match_count > 0:
        # Some tags or keywords matched
        match_ratio = min(1.0, match_count / (len(proj_stack_lower) if proj_stack_lower else 3))
        base_score = 40.0 + (match_ratio * 30.0) # Scale between 40 and 70
    else:
        # No match at all
        base_score = 10.0
        
    # Seniority Boost
    seniority_boost = 0
    seniority_lower = dev_seniority.lower()
    if "senior" in seniority_lower:
        seniority_boost = 10
    elif "mid" in seniority_lower:
        seniority_boost = 5
        
    final_score = base_score + seniority_boost
    
    # Floor and Cap
    if final_score < 10.0:
        final_score = 10.0
    if final_score > 100.0:
        final_score = 100.0
        
    logger.info(f"Final Score calculated: {final_score}")
    return round(final_score, 1)

def batch_calculate_matches(dev_skills: List[str], dev_seniority: str, projects: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    results = []
    for proj in projects:
        score = calculate_match_score(
            dev_skills=dev_skills,
            dev_seniority=dev_seniority,
            project_tech_stack=proj.get('techStack', []),
            project_description=proj.get('description', "")
        )
        results.append({
            "projectId": proj.get('id'),
            "score": score
        })
    return results
