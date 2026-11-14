// Lokaler, absichtlich schlichter 3DEN-freundlicher Dialog (keine externen UI-Mods).
class DYN_RscText {
    type = 0; idc = -1; style = 0; font = "RobotoCondensed";
    sizeEx = 0.034; colorText[] = {1,1,1,1};
    colorBackground[] = {0,0,0,0}; shadow = 0;
    text = "";
};
class DYN_RscButton {
    type = 1; idc = -1; style = 2; font = "RobotoCondensed";
    sizeEx = 0.032; text = ""; shadow = 0;
    colorText[] = {1,1,1,1}; colorDisabled[] = {0.5,0.5,0.5,1};
    colorBackground[] = {0.14,0.20,0.26,1};
    colorBackgroundActive[] = {0.23,0.38,0.47,1};
    colorBackgroundDisabled[] = {0.15,0.15,0.15,1};
    colorFocused[] = {0.23,0.38,0.47,1}; colorShadow[] = {0,0,0,0};
    colorBorder[] = {0,0,0,0}; borderSize = 0;
    offsetX = 0; offsetY = 0; offsetPressedX = 0; offsetPressedY = 0;
    soundEnter[] = {"",0,1}; soundPush[] = {"",0,1};
    soundClick[] = {"",0,1}; soundEscape[] = {"",0,1};
};
class DYN_RscListBox {
    type = 5; idc = -1; style = 16; font = "RobotoCondensed";
    sizeEx = 0.03; rowHeight = 0.035;
    colorText[] = {1,1,1,1}; colorSelect[] = {1,1,1,1};
    colorSelect2[] = {1,1,1,1}; colorBackground[] = {0.06,0.09,0.11,1};
    colorSelectBackground[] = {0.15,0.31,0.40,1};
    colorSelectBackground2[] = {0.15,0.31,0.40,1};
    colorScrollbar[] = {1,1,1,1}; colorPicture[] = {1,1,1,1};
    colorPictureSelected[] = {1,1,1,1}; colorPictureDisabled[] = {1,1,1,0.3};
    colorDisabled[] = {0.5,0.5,0.5,1};
    soundSelect[] = {"",0,1};
    shadow = 0; period = 1;
    class ListScrollBar { color[] = {1,1,1,1}; autoScrollEnabled = 0; width = 0; height = 0; scrollSpeed = 0.06; arrowEmpty = "\A3\ui_f\data\gui\cfg\scrollbar\arrowEmpty_ca.paa"; arrowFull = "\A3\ui_f\data\gui\cfg\scrollbar\arrowFull_ca.paa"; border = "\A3\ui_f\data\gui\cfg\scrollbar\border_ca.paa"; thumb = "\A3\ui_f\data\gui\cfg\scrollbar\thumb_ca.paa"; };
};
class DYN_HostDialog {
    idd = 7970; movingEnable = 0; enableSimulation = 1;
    onLoad = "[] call DYN_fnc_uiRefresh";
    class controlsBackground {
        class BG: DYN_RscText {
            x = safezoneX + safezoneW * 0.19;
            y = safezoneY + safezoneH * 0.18;
            w = safezoneW * 0.62; h = safezoneH * 0.64;
            colorBackground[] = {0.035,0.055,0.07,0.96};
        };
    };
    class controls {
        class Title: DYN_RscText {
            text = "DMCS | EINSATZFUEHRUNG";
            x = safezoneX + safezoneW * 0.21; y = safezoneY + safezoneH * 0.205;
            w = safezoneW * 0.23; h = safezoneH * 0.04;
        };
        class Tasks: DYN_RscListBox {
            idc = 1800;
            onLBSelChanged = "_this call DYN_fnc_uiSelect";
            x = safezoneX + safezoneW * 0.21; y = safezoneY + safezoneH * 0.26;
            w = safezoneW * 0.58; h = safezoneH * 0.29;
        };
        class Type: DYN_RscListBox {
            idc = 1801;
            x = safezoneX + safezoneW * 0.21; y = safezoneY + safezoneH * 0.57;
            w = safezoneW * 0.28; h = safezoneH * 0.18;
        };
        class Zone: DYN_RscListBox {
            idc = 1802;
            x = safezoneX + safezoneW * 0.51; y = safezoneY + safezoneH * 0.57;
            w = safezoneW * 0.28; h = safezoneH * 0.18;
        };
        class Create: DYN_RscButton {
            text = "Anlegen"; x = safezoneX + safezoneW * 0.21; y = safezoneY + safezoneH * 0.76;
            w = safezoneW * 0.09; h = safezoneH * 0.042;
            onButtonClick = "['create'] call DYN_fnc_uiAction";
        };
        class Edit: Create { text = "Bearbeiten"; x = safezoneX + safezoneW * 0.31; onButtonClick = "['edit'] call DYN_fnc_uiAction"; };
        class Start: Create { text = "Aktivieren"; x = safezoneX + safezoneW * 0.41; onButtonClick = "['activate'] call DYN_fnc_uiAction"; };
        class Pause: Create { text = "Pausieren"; x = safezoneX + safezoneW * 0.51; onButtonClick = "['pause'] call DYN_fnc_uiAction"; };
        class Resume: Create { text = "Fortsetzen"; x = safezoneX + safezoneW * 0.61; onButtonClick = "['resume'] call DYN_fnc_uiAction"; };
        class Remove: Create { text = "Entfernen"; x = safezoneX + safezoneW * 0.71; w = safezoneW * 0.08; onButtonClick = "['remove'] call DYN_fnc_uiAction"; };
        class CivOn: DYN_RscButton {
            text = "Zivil EIN";
            x = safezoneX + safezoneW * 0.43; y = safezoneY + safezoneH * 0.205;
            w = safezoneW * 0.10; h = safezoneH * 0.042;
            onButtonClick = "['civ_on'] call DYN_fnc_uiAction";
        };
        class CivOff: DYN_RscButton {
            text = "Zivil AUS";
            x = safezoneX + safezoneW * 0.54; y = safezoneY + safezoneH * 0.205;
            w = safezoneW * 0.10; h = safezoneH * 0.042;
            onButtonClick = "['civ_off'] call DYN_fnc_uiAction";
        };
        class CivStatus: DYN_RscText {
            idc = 1803;
            text = "Zivilisten: AUS";
            x = safezoneX + safezoneW * 0.43; y = safezoneY + safezoneH * 0.236;
            w = safezoneW * 0.35; h = safezoneH * 0.021;
            sizeEx = 0.025;
        };
        class Refresh: DYN_RscButton {
            text = "Aktualisieren"; x = safezoneX + safezoneW * 0.65; y = safezoneY + safezoneH * 0.205;
            w = safezoneW * 0.14; h = safezoneH * 0.042;
            onButtonClick = "['refresh'] call DYN_fnc_uiAction";
        };
    };
};
