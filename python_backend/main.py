from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import logging
from typing import List, Optional, Dict, Any
from github_service import fetch_github_data
from ai_service import analyze_developer_metrics
from matching_service import batch_calculate_matches

# Initialize logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="DevSync AI Analyzer")

class AnalyzeRequest(BaseModel):
    username: str
    token: str

class AnalyzeResponse(BaseModel):
    githubUrl: str
    githubSeniority: str
    aiBio: str
    topAiSkills: List[str]
    publicRepos: int
    followers: int
    accountAgeYears: int
    location: Optional[str] = None
    topRepositories: Optional[List[Dict[str, Any]]] = None

class MatchProjectRequest(BaseModel):
    id: str
    techStack: List[str]
    description: str = ""

class MatchRequest(BaseModel):
    devSkills: List[str]
    devSeniority: str
    projects: List[MatchProjectRequest]

class MatchResult(BaseModel):
    projectId: str
    score: float

class MatchResponse(BaseModel):
    matches: List[MatchResult]

@app.post("/analyze", response_model=AnalyzeResponse)
async def analyze_github_profile(request: AnalyzeRequest):
    try:
        logger.info(f"Received analysis request for GitHub user: {request.username}")
        
        if not request.token:
            raise HTTPException(status_code=400, detail="GitHub Access Token is required")
            
        # 1. Fetch data from github_service
        github_metrics = fetch_github_data(request.username, request.token)
        
        # 2. Process data with ai_service
        ai_result = analyze_developer_metrics(github_metrics)
        
        return AnalyzeResponse(
            githubUrl=f"https://github.com/{request.username}",
            githubSeniority=ai_result.githubSeniority,
            aiBio=ai_result.aiBio,
            topAiSkills=ai_result.topAiSkills,
            publicRepos=ai_result.publicRepos,
            followers=ai_result.followers,
            accountAgeYears=ai_result.accountAgeYears,
            location=ai_result.location,
            topRepositories=ai_result.topRepositories
        )
    except Exception as e:
        logger.error(f"Error analyzing profile: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/matches/calculate", response_model=MatchResponse)
async def calculate_matches(request: MatchRequest):
    try:
        logger.info(f"Calculating matches for {len(request.projects)} projects")
        results = batch_calculate_matches(
            dev_skills=request.devSkills,
            dev_seniority=request.devSeniority,
            projects=[p.dict() for p in request.projects]
        )
        return MatchResponse(matches=[MatchResult(**r) for r in results])
    except Exception as e:
        logger.error(f"Error calculating matches: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/")
def read_root():
    return {"message": "DevSync AI Analyzer API is running"}
