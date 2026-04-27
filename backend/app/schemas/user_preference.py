from pydantic import BaseModel
from typing import List, Optional, Literal

TabName = Literal["calendar", "todo", "note"]
ThemeMode = Literal["light", "dark", "system"]


class UserPreferenceResponse(BaseModel):
    enabled_tabs: List[TabName]
    tab_order: List[TabName]
    initial_tab: TabName
    theme_mode: ThemeMode

    class Config:
        from_attributes = True


class UserPreferenceUpdate(BaseModel):
    enabled_tabs: Optional[List[TabName]] = None
    tab_order: Optional[List[TabName]] = None
    initial_tab: Optional[TabName] = None
    theme_mode: Optional[ThemeMode] = None