local descEN = [[This mod helps you create underpass of any topology freely.
Usage:
1. Find entries in Road Construction menu
2. Place at least two entres over the map
3. Click on the finish button that apperas on the screen
4. Finished!

* This mod requires "Shader enhancement" mod to render textures correctly.

Changelog:
1.4
- Redesigned the dialogue logic for being player-friendly
1.3
- Support to modify finished underground station
- Correction of sign name position
- Remastered icons
1.2
- Support of station name sign
1.1
- Adaption of underground station
]]

local descCN = [[本模组可自由建造人行地道
使用方法:
1. 在道路建设菜单中找到人行地道入口选项
2. 在地图上摆放至少两个入口
3. 点击屏幕上出现的完成按钮
4. 完成建造!

* 本模组需要“着色器增强”模组方可正确渲染

更新日志:
1.4
- 重新设计了对话框逻辑对玩家更友好
1.3
- 增加修改已完成的地下车站的能力
- 修正了站台名上文字的位置错误
- 重新制作了图标
1.2
- 增加对站名牌的支持
1.1
- 增加对地下车站的支持
]]


local descTC = [[本模組可自由建造人行地道
使用方法:
1. 在道路建設菜單中找到人行地道入口選項
2. 在地圖上擺放至少兩個入口
3. 點擊螢幕上出現的完成按鈕
4. 完成建造!

* 本模組需要“著色器增強”模組方可正確渲染

更新日誌:
1.4
- 重新設計了對話方塊邏輯對玩家更友好
1.3
- 增加修改已完成的地下車站的能力
- 修正了月臺名上文字的位置錯誤
- 重新製作了圖示
1.2
- 增加對站名牌的支持
1.1
- 增加對地下車站的支持
]]


function data()
    return {
        en = {
            ["name"] = "Underpass",
            ["desc"] = descEN,
            ["MENU_WALL"] = "Wall Pattern",
            ["MENU_FLOOR_STYLE"] = "Floor Pattern",
            ["MENU_FENCE_STYLE"] = "Fence Style",
            ["MENU_FENCE_GLASS"] = "Glass",
            ["MENU_FENCE_IRON"] = "Iron",
            ["MENU_FENCE_CONCR"] = "Concrete",
            ["MENU_WIDTH"] = "Width(m)",
            ["MENU_NAME"] = "Underpass/Undergroudn Entry",
            ["MENU_DESC"] = "An underpass or underground station entry",
            ["BUILT"] = " (modifiable)",
            ["UNDERPASS_CON"] = "Underpass Construction",
            ["STATION_CON"] = "Underground Station Construction",
            ["SHADER_WARNING"] = [["Underpass" mod requires "Shader Enhancement" mod, you will see strange texture without this mod.]],
            ["STATION_MAX_LIMIT"] = 
[[You can only build at most 8 platform levels into one
station. Uncheck platform levels to reduce them.]],
            ["STATION_CAN_FINALIZE"] =   
[[You can reconfigurate the platform layout in modular way.
Click on the finalize button on the left to link all 
platforms and entries.]],
            ["STATION_NEED_ENTRY"] =     
[[At least an entry and a platform level are needed to
finalize an underground station.]],
            ["UNDERPASS_CAN_FINALIZE"] = 
[[Click on the finalize button on the left to link all entries
to build an underpass.
Please keep in mind that the game pathfinding algorithm
takes always the shortest path, you need to design carefully
the entry layout to make the pathes short.]],
            ["UNDERPASS_NEED_ENTRY"] = 
[[At least two entries are needed to finalize an underpass.
If you want to modify an existing station, click it and
check the checkbox before the icon.]]
        },
        zh_CN = {
            ["name"] = "人行地道",
            ["desc"] = descCN,
            ["MENU_WALL"] = "墙面",
            ["MENU_FLOOR_STYLE"] = "地面纹理",
            ["MENU_FENCE_STYLE"] = "围栏风格",
            ["MENU_FENCE_GLASS"] = "玻璃",
            ["MENU_FENCE_IRON"] = "栏杆",
            ["MENU_FENCE_CONCR"] = "水泥",
            ["MENU_WIDTH"] = "宽度(米)",
            ["MENU_NAME"] = "地道/地下车站入口",
            ["MENU_DESC"] = "通往人行地道或地下车站的入口.",
            ["BUILT"] = " (可修改)",
            ["SHADER_WARNING"] = [["人行地道"模组需要"着色器增强"模组的支持方可运行，否则您将看到不正常的贴图]],
            ["Warning"] = "警告",
            ["UNDERPASS_CON"] = "建造人行地道",
            ["STATION_CON"] = "建造地下车站",
            ["STATION_MAX_LIMIT"] = 
[[在一座地下车站中最多只能建造八个站台层，
点击站台前的圆点减少站台层。]],
            ["STATION_CAN_FINALIZE"] = 
[[您可以通过模块化的方式配置站厅布局。
在设置完所有站厅和出入口后，点击左侧的
“完成”按钮完成车站建造。]],
            ["STATION_NEED_ENTRY"] = 
[[每座地下车站至少需要设置一个出入口。]],
            ["UNDERPASS_CAN_FINALIZE"] = 
[[设置完所有人行地道入口后，点击左侧的
“完成”按钮完成人行地道建造。
注意游戏的择路算法是最短路径，为了确保
建设的地道被使用，请仔细规划地道布局]],
            ["UNDERPASS_NEED_ENTRY"] = 
[[每条人行地道至少需要一对出入口。
如果您希望修改一座已建成车站，点击车站
主体，然后在下方列表的圆圈中选中该车站。]]
        },
        zh_TW = {            
            ["name"] = "人行地道",
            ["desc"] = descTC,            
            ["MENU_WALL"] = "牆面",
            ["MENU_FLOOR_STYLE"] = "地面紋理",
            ["MENU_FENCE_STYLE"] = "圍欄風格",
            ["MENU_FENCE_GLASS"] = "玻璃",
            ["MENU_FENCE_IRON"] = "欄杆",
            ["MENU_FENCE_CONCR"] = "水泥",
            ["MENU_WIDTH"] = "寬度(米)",            
            ["MENU_NAME"] = "地道/地下車站入口",
            ["MENU_DESC"] = "通往人行地道或地下車站的入口.",
            ["SHADER_WARNING"] = [["人行地道"模組需要"著色器增強"模組的支持方可運行，否則您將看到不正常的貼圖]],
            ["Warning"] = "警告",            
            ["BUILT"] = " (可修改)",
            ["UNDERPASS_CON"] = "建造人行地道",
            ["STATION_CON"] = "建造地下車站",
            ["STATION_MAX_LIMIT"] = 
[[在一座地下車站中最多只能建造八個月臺層，
點擊月臺前的圓點減少月臺層。]],
            ["STATION_CAN_FINALIZE"] = 
[[您可以通過模組化的方式配置站廳佈局。
在設置完所有站廳和出入口後，點擊左側的
“完成”按鈕完成車站建造。]],
            ["STATION_NEED_ENTRY"] = 
[[每座地下車站至少需要設置一個出入口。]],
            ["UNDERPASS_CAN_FINALIZE"] = 
[[設置完所有人行地道入口後，點擊左側的
“完成”按鈕完成人行地道建造。
注意遊戲的擇路演算法是最短路徑，為了確保
建設的地道被使用，請仔細規劃地道佈局]],
            ["UNDERPASS_NEED_ENTRY"] = 
[[每條人行地道至少需要一對出入口。
如果您希望修改一座已建成車站，點擊車站
主體，然後在下方列表的圓圈中選中該車站。]]
        }
    }
end
