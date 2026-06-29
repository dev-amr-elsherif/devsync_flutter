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
    logger.info("Analyzing developer GitHub metrics...")

    public_repos      = metrics.get('public_repos', 0)
    total_stars       = metrics.get('total_stars_earned', 0)
    language_dist     = metrics.get('language_distribution', {})
    followers         = metrics.get('followers', 0)
    account_age_years = metrics.get('account_age_years', 0)
    repo_topics       = metrics.get('repo_topics', [])

    # 1. Seniority — نظام نقاط مركّب
    seniority_score = 0

    if public_repos >= 40:   seniority_score += 3
    elif public_repos >= 20: seniority_score += 2
    elif public_repos >= 5:  seniority_score += 1

    if total_stars >= 50:    seniority_score += 3
    elif total_stars >= 15:  seniority_score += 2
    elif total_stars >= 5:   seniority_score += 1

    if account_age_years >= 6:   seniority_score += 3
    elif account_age_years >= 3: seniority_score += 2
    elif account_age_years >= 1: seniority_score += 1

    if seniority_score >= 7:
        seniority = "Lead"
    elif seniority_score >= 4:
        seniority = "Senior"
    elif seniority_score >= 2:
        seniority = "Mid-Level"
    else:
        seniority = "Junior"

    # 2. Top Skills — max 8 من اللغات + 3 من الـ topics
    sorted_languages = sorted(
        language_dist.items(),
        key=lambda item: item[1],
        reverse=True
    )
    top_skills = [lang for lang, _ in sorted_languages[:8]]

    tech_topics = [
        t for t in repo_topics
        if t.lower() not in {s.lower() for s in top_skills}
    ][:3]
    top_skills = top_skills + tech_topics

    # 3. Bio
    github_bio = metrics.get('github_bio')
    if github_bio and github_bio.strip():
        bio = github_bio.strip()
    else:
        skills_str = ", ".join(top_skills[:4]) if top_skills else "various technologies"
        bio = (
            f"{seniority} developer with {public_repos} public repositories, "
            f"specializing in {skills_str}."
        )
        if total_stars > 0:
            bio += f" Earned {total_stars} stars across their open-source work."
        if followers > 0:
            bio += f" Followed by {followers} developers on GitHub."

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