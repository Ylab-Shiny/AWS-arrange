##############################################################################################################################
#### 建物エネルギーデータ分析ツール ui.R #####################################################################################
##############################################################################################################################

# パッケージ一覧 -----------------------------------------------------------------
library(shiny)
library(shinydashboard)

# Webページ構成要素 --------------------------------------------------------------
# header #
header <- dashboardHeader(title = "建物エネルギーデータ分析ツール", titleWidth = 500)

# sidebar -----------------------------------------------------------------

sidebar <- dashboardSidebar(
  # サイドバーメニュー
  sidebarMenu(
    menuItem("データセット[kWh]", tabName = "table"),
    menuItem("トレンドグラフ", tabName = "trend", badgeColor = "red"),
    menuItem("クラスタリング", tabName = "clustering")
    # menuItem("前処理", tabName = "disposal")
    # menuItem("ヒートマップ", tabName = "heatmap")
  ),
  
  # 前処理
  # checkboxGroupInput("前処理",
  #                    h5("前処理"),
  #                    choices = list("外れ値あり" = 1,
  #                                   "外れ値なし" = 2),
  #                    selected = 1),
  
  # ファイルのアップロードUI
  fileInput("file", "csvファイルをアップロードしてください",
            accept = c("text/csv", "text/comma-separated-values,text/plain", ".csv")),
  
  # カレンダーの出力
  uiOutput("DateRange"),
  
  # トレンドグラフに描画する項目選択
  uiOutput("selectDeps"),
  
  sliderInput(inputId = "RangeY", label = "Y軸（電力消費[kW]）の範囲をを指定してください",
              min = 0, max = 4000, value = c(0, 4000), step = 50),
  # # ヒートマップ
  # uiOutput("heatm"),
  
  # クラスタリングの対象とする項目の選択
  uiOutput("target_cluster")
  
  # 前処理の選択
)

# body --------------------------------------------------------------------

body <- dashboardBody(
  tabItems(
    tabItem(
      h1("ようこそ『建物エネルギーデータ分析ツール』へ"),
      tabName = "table",
      DT::dataTableOutput("DataTable")),
    
    tabItem(tabName = "trend",
            
            # トレンドグラフの描画
            plotOutput("trendGragh")
            
            # # ヒートマップの描画
            # plotOutput("heatm")
            
    ),
    
    #クラスタリングの描画
    tabItem(tabName = "clustering",
            
            # アイコン
            infoBoxOutput(width = 3, "Max"),
            infoBoxOutput(width = 3, "Min"),
            infoBoxOutput(width = 3, "Mean"),
            
            # クラスタセンターの描画
            plotOutput("qqq")
    )
    
    # ヒートマップの描画
    
    # tabItem(tabName = "heatmap",
    # 
    #         # アイコン
    #          infoBoxOutput(width = 3, "Max"),
    #          infoBoxOutput(width = 3, "Min"),
    #          infoBoxOutput(width = 3, "Mean"),
    # 
    #         # ヒートマップの描画
    #         plotOutput("gp")

# color -------------------------------------------------------------------

# tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")),　# 一番上の線
# tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "styles2.css")),　#追加
# tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "styles3.css")),　#追加

# Also add some custom CSS to make the title background area the same #追加
# color as the rest of the header.

# tags$head(tags$style(HTML('
#                           /* logo */
#                           .skin-blue .main-header .logo {
#                           background-color: #20b2aa;
#                           }', # ロゴ部分背景色
# 
#                           '
#                           /* logo when hovered */
#                           .skin-blue .main-header .logo:hover {
#                           background-color: #5f9ea0;
#                           }', # ロゴ部分選択時背景色
# 
#                           '
#                           /* navbar (rest of the header) */
#                           .skin-blue .main-header .navbar {
#                           background-color: #20b2aa;
#                           }', # ロゴ以外上部背景色
# 
#                           '
#                           /* main sidebar */
#                           .skin-blue .main-sidebar {
#                           background-color: #585858;
#                           }', # サイドバー内背景色
# 
#                           '
#                           /* active selected tab in the sidebarmenu */
#                           .skin-blue .main-sidebar .sidebar .sidebar-menu .active a{
#                           background-color: #585858;
#                           }', # サイドバー ( 選択項目①)
# 
#                           '
#                           /* other links in the sidebarmenu */
#                           .skin-blue .main-sidebar .sidebar .sidebar-menu a{
#                           background-color: #585858;
#                           color: #FFFFFF;
#                           }', # サイドバー ( 選択項目②･③) # 文字色
# 
#                           '
#                           /* other links in the sidebarmenu when hovered */
#                           .skin-blue .main-sidebar .sidebar .sidebar-menu a:hover{
#                           background-color: #424242;
#                           }', # 選択時背景色
# 
#                           '
#                           /* toggle button when hovered  */
#                           .skin-blue .main-header .navbar .sidebar-toggle:hover{
#                           background-color: #5f9ea0;
#                           }'　# サイドバー選択時背景色 (三本線のやつ)
# 
# )))

   )
 )


# 構成要素の組み立て ---------------------------------------------------------------
dashboardPage(header, sidebar, body)