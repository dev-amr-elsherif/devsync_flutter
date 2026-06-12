import logging
from pydantic import BaseModel
from typing import List, Optional, Dict, Any

logger = logging.getLogger(__name__)

class AIAnalysisResult(BaseModel):
    aiBio: str
    githubSeniority: str
    topAiSkills: List[str]
    publicRepos: int
    followers: int
    accountAgeYears: int
    location: Optional[str] = None
    topRepositories: Optional[List[Dict[str, Any]]] = None

def analyze_developer_metrics(metrics: dict) -> AIAnalysisResult:
    logger.info("Executing algorithmic analysis of GitHub metrics exclusively via Python.")
    
    public_repos = metrics.get('public_repos', 0)
    total_stars = metrics.get('total_stars_earned', 0)
    language_dist = metrics.get('language_distribution', {})
    username = metrics.get('username', 'Developer')
    followers = metrics.get('followers', 0)
    account_age_years = metrics.get('account_age_years', 0)
    
    # 1. Determine Seniority using basic thresholds
    if public_repos >= 40 or total_stars >= 50 or account_age_years >= 6:
        seniority = "Lead"
    elif public_repos >= 20 or total_stars >= 15 or account_age_years >= 3:
        seniority = "Senior"
    elif public_repos >= 5 or total_stars >= 5 or account_age_years >= 1:
        seniority = "Mid-Level"
    else:
        seniority = "Junior"
        
    # 2. Extract Top Skills
    # Sort languages by frequency (number of repos using that language) descending
    sorted_languages = sorted(language_dist.items(), key=lambda item: item[1], reverse=True)
    top_skills = [lang[0] for lang in sorted_languages[:4]] # Take up to top 4 max
    
    # 3. Use actual GitHub Bio if available, else generate a fast dynamic bio 
    github_bio = metrics.get('github_bio')
    if github_bio and github_bio.strip():
        bio = github_bio.strip()
    else:
        skills_str = ", ".join(top_skills) if top_skills else "various technologies"
        bio = f"{seniority} developer with {public_repos} public projects, focusing on {skills_str}. "
        if total_stars > 0:
            bio += f"Earned {total_stars} stars across their repositories."
    
    return AIAnalysisResult(
        aiBio=bio,
        githubSeniority=seniority,
        topAiSkills=top_skills,
        publicRepos=public_repos,
        followers=followers,
        accountAgeYears=account_age_years,
        location=metrics.get('location'),
        topRepositories=metrics.get('top_repos', [])
    )
