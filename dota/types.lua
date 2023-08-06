---@meta
---@diagnostic disable:duplicate-doc-field

---@class Vector3D
---@field x number
---@field y number
---@field z number

---@class Animation
---@field file string
---@field name string

---@enum HeroType
local HeroType = {
    MELEE = 1,
    RANGE = 2
}

---@class Hero
---@field abilities Ability[]
---@field name string
---@field imageBase85 string?
---@field image any
---@field loop fun()?
---@field model number
---@field weapon number?
---@field animations { walk: Animation, fight: Animation }?
---@field stats PlayerStats
---@field lastAttack number?
---@field storage table?

---@class Ability
---@field name string
---@field imageBase85 string?
---@field image any
---@field type AbilityType
---@field waitForTarget boolean?
---@field onUse fun(...): boolean?
---@field onToggle fun(...)?
---@field whileActive fun(...)?
---@field storage table?
---@field cooldown number?
---@field manaRequired number?
---@field lastUsed number?
---@field toggled boolean?
---@field useThread boolean?
---@field targetRange number?
---@field onScriptUnload fun()?

---@enum TypeState
local TypeState = {
    NONE = 0,
    WAIT_FOR_TARGET = 1
}

---@enum AbilityType
local AbilityType = {
    PASSIVE = 0,
    VECTOR = 1,
    TARGET_ENTITY = 2,
    TARGET_ENEMY = 3,
    TARGET_TEAM = 4,
    TARGET_POINT = 5,
    INSTANT = 6,
    TOGGLEABLE = 7
};

---@class PlayerStats
---@field maxHealth number
---@field maxMana number
---@field healthRegen number
---@field manaRegen number
---@field damage number
---@field attackSpeed number
---@field speed number
---@field attackRange number

---@enum PlayerStat
local PlayerStat = {
    maxHealth = 0,
    maxMana = 1,
    healthRegen = 2,
    manaRegen = 3,
    damage = 4,
    attackSpeed = 5,
    speed = 6,
    attackRange = 7,
}

---@class Item
---@field stats table<PlayerStat, number>? ����� ������� ���� �������
---@field name string �������� ��������
---@field manaRequired boolean? ����, ����������� ��� ������������� ��������
---@field type ItemType | number ��� ��������
---@field targetRange number? ������ ����������
---@field toggled boolean? ������� �� �������
---@field onWaitForTarget fun(...)? ������� ����������� ��� �������� ������ ���� (������ ��� ItemType.TARGET_*)
---@field category 'main' | 'upgrades' ��������� �������� ��� ��������
---@field subCategory 'resources' | 'attributes' | 'gear' | 'other' | 'accessories' | 'support' | 'magic' | 'armour' | 'weapon' | 'artefact' ����������� � ��������
---@field iconBase85 string? ������ � base85
---@field icon any �������� ��� ImGui
---@field onUse fun(...): boolean? ������� ����������� ����� ������ ���� / ������������ � �.�.. � �������� ���������� ��������: TARGET_POINT/VECTOR - ��������� ������� � 3� ����, TARGET_* - ����� ���������� ������, ��� ��������� ����� �������� nil
---@field onUseThread boolean? �������� ������� ����� lua_thread.create
---@field storage table? ��������� ������
---@field cooldown number? ����� �����������
---@field lastUsed number?

---@enum ItemType
local ItemType = AbilityType;



return {
    AbilityType = AbilityType,
    ItemType = AbilityType,
    HeroType = HeroType
};