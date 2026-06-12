import requests
import logging

logger = logging.getLogger(__name__)

def fetch_github_data(username: str, token: str):
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github.v3+json"
    }
    
    logger.info(f"Fetching GitHub data for {username}")
    
    # Get List of Repositories
    repos_url = f"https://api.github.com/user/repos?sort=updated&per_page=30"
    repos_res = requests.get(repos_url, headers=headers)
    
    if repos_res.status_code != 200:
        logger.error(f"GitHub API Error: {repos_res.status_code} - {repos_res.text}")
        raise Exception(f"Failed to fetch repositories. Status: {repos_res.status_code}")
        
    repos = repos_res.json()
    
    # Get User Profile details
    user_url = "https://api.github.com/user"
    user_res = requests.get(user_url, headers=headers)
    account_age_years = 0
    followers = 0
    public_repos_count = len(repos)
    
    if user_res.status_code == 200:
        user_data = user_res.json()
        followers = user_data.get('followers', 0)
        public_repos_count = user_data.get('public_repos', len(repos))
        
        # Calculate account age
        import datetime
        created_at_str = user_data.get('created_at')
        if created_at_str:
            try:
                # Format: "2015-05-15T15:00:00Z"
                created_at = datetime.datetime.strptime(created_at_str, "%Y-%m-%dT%H:%M:%SZ")
                now = datetime.datetime.utcnow()
                account_age_years = now.year - created_at.year
                if now.month < created_at.month or (now.month == created_at.month and now.day < created_at.day):
                    account_age_years -= 1
            except Exception as e:
                logger.error(f"Error parsing created_at: {e}")
                
    # Get actual github bio and location
    github_bio = user_data.get('bio') if 'user_data' in locals() else None
    location = user_data.get('location') if 'user_data' in locals() else None
    
    # Aggregate data
    languages = {}
    total_stars = 0
    topics = set()
    valid_repos = []
    
    for repo in repos:
        # Ignore forks for primary skill assessment, unless you want them
        if repo.get('fork', False):
            continue
            
        valid_repos.append(repo)
            
        lang = repo.get('language')
        if lang:
            languages[lang] = languages.get(lang, 0) + 1
            
        total_stars += repo.get('stargazers_count', 0)
        
        for topic in repo.get('topics', []):
            topics.add(topic)

    # Sort valid_repos to get top 3 repositories by stars, then update date
    sorted_repos = sorted(valid_repos, key=lambda x: (x.get('stargazers_count', 0), x.get('updated_at', '')), reverse=True)
    top_repos_snips = []
    for r in sorted_repos[:3]:
        top_repos_snips.append({
            "name": r.get('name'),
            "description": r.get('description'),
            "language": r.get('language'),
            "stargazers_count": r.get('stargazers_count', 0),
            "forks_count": r.get('forks_count', 0),
            "html_url": r.get('html_url')
        })

    # Simplified user snippet to send
    metrics = {
        "username": username,
        "public_repos": public_repos_count,
        "total_stars_earned": total_stars,
        "language_distribution": languages,
        "repo_topics": list(topics),
        "followers": followers,
        "account_age_years": account_age_years,
        "github_bio": github_bio,
        "location": location,
        "top_repos": top_repos_snips
    }
    
    logger.info(f"Metrics gathered: {metrics}")
    return metrics
