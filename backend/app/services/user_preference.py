import json
from sqlalchemy.orm import Session
from app.models.user_preference import UserPreference
from app.schemas.user_preference import UserPreferenceUpdate

DEFAULT_TABS = ["calendar", "todo", "note"]


def _serialize_tabs(tabs: list[str]) -> str:
    return json.dumps(tabs)


def _deserialize_tabs(value: str) -> list[str]:
    return json.loads(value)


def _to_response(pref: UserPreference):
    return {
        "enabled_tabs": _deserialize_tabs(pref.enabled_tabs),
        "tab_order": _deserialize_tabs(pref.tab_order),
        "initial_tab": pref.initial_tab,
        "theme_mode": pref.theme_mode,
    }


def get_or_create_preferences(db: Session, user_id: int):
    pref = db.query(UserPreference).filter(
        UserPreference.user_id == user_id,
    ).first()

    if not pref:
        pref = UserPreference(
            user_id=user_id,
            enabled_tabs=_serialize_tabs(DEFAULT_TABS),
            tab_order=_serialize_tabs(DEFAULT_TABS),
            initial_tab="calendar",
            theme_mode="system",
        )
        db.add(pref)
        db.commit()
        db.refresh(pref)

    return _to_response(pref)


def update_preferences(db: Session, user_id: int, payload: UserPreferenceUpdate):
    pref = db.query(UserPreference).filter(
        UserPreference.user_id == user_id,
    ).first()

    if not pref:
        pref = UserPreference(
            user_id=user_id,
            enabled_tabs=_serialize_tabs(DEFAULT_TABS),
            tab_order=_serialize_tabs(DEFAULT_TABS),
            initial_tab="calendar",
            theme_mode="system",
        )
        db.add(pref)
        db.commit()
        db.refresh(pref)

    if payload.enabled_tabs is not None:
        pref.enabled_tabs = _serialize_tabs(payload.enabled_tabs)

    if payload.tab_order is not None:
        pref.tab_order = _serialize_tabs(payload.tab_order)

    if payload.initial_tab is not None:
        pref.initial_tab = payload.initial_tab

    if payload.theme_mode is not None:
        pref.theme_mode = payload.theme_mode

    db.commit()
    db.refresh(pref)
    return _to_response(pref)