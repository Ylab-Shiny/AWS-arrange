##############################################################################################################################
#### 建物エネルギーデータ分析ツール server.R #################################################################################
##############################################################################################################################

# 外部パッケージ一覧 ---------------------------------------------------------------
library(shiny)
library(dplyr)
library(ggplot2)
library(DT)
library(readr)
library(tcltk)
library(ggTimeSeries)
library(plyr)
library(data.table) 
library(stats)
library(tseries)
library(forecast)
library(imputeTS)
library(reshape2)

library(tidyverse)
library(zoo)
library(hms)
library(scales)
library(gridExtra)

# browser設定 ---------------------------------------------------------------
options(shiny.launch.browser = T)

# 外れ値処理の関数化 ---------------------------------------------------------------------
repOutliersNA <- function(Column) {
  xx1 <- Column %>% mutate(
    Norm = (Column-min(Column, na.rm = T)) / (max(Column, na.rm = T)-min(Column, na.rm = T)) * (1-0) + 0
  )
  qq <- data.frame(quantile(xx1[[2]],c(0.25, 0.75), na.rm = T))
  Q1 <- qq[1, 1]
  Q3 <- qq[2, 1]
  
  outer_l_Q1 <- Q1 - 1.5 * (Q3 - Q1)
  outer_m_Q3 <- Q3 + 3 * (Q3 - Q1)
  outer_ll <- which(xx1$Norm < outer_l_Q1)
  outer_mm <- which(xx1$Norm > outer_m_Q3)
  
  # 重複なく昇順に行番号を抽出
  row_num_out <- unique(c(outer_ll, outer_mm)) %>% sort()
  
  # 外れ値の出力
  outer_outlier <- cbind.data.frame(Column[row_num_out,], row_number = row_num_out)
  Column_removeOutliers <- Column
  Column_removeOutliers[outer_outlier$row_number, 1] <- NA
  
  
  return(Column_removeOutliers)
}




# shinyサーバー ---------------------------------------------------------------
shinyServer(function(input, output, session){
  
  # アップロードされたデータ ------------------------------------------------------------
  # 対象とするデータは24期周期の1時間間隔の時系列データ
  passData <- reactive({
    if(!is.null(input$file)) {
      # 文字コード：UTF-8
      firstData <- read_csv(input$file$datapath)
      names(firstData)[1] <- "label"
    } else {
      firstData <- NULL
    }
    
    return(firstData)
  })
  
  # ヒートマップ列選択の設定UIの出力 -------------------------------------------------------
  
  
  # カレンダーによる日付範囲の設定UIの出力 ----------------------------------------------------
  output$DateRange <- renderUI({
    dateRangeInput(inputId = "theRange", label = "日付範囲を指定してください",
                   start = substr(passData()$label[1], 1, 10),
                   end = substr(passData()$label[nrow(passData())], 1, 10),
                   format = "yyyy-mm-dd"
    )
  })
  
  # カレンダーの範囲期間を抽出したデータ ------------------------------------------------------
  passData2 <- reactive({
    # 日付ラベルを追加
    firstData <- passData() %>% mutate(date = substr(label, 1, 10))
    secondData <- firstData %>% filter(
      date >= input$theRange[1] & date <= input$theRange[2]
    ) %>% select(-c(date))
    
    # labelの型をPOSIXctに変換 タイムゾーン：UTC
    secondData$label <- as.POSIXct(secondData$label, "%Y-%m-%d %H:%M:%S", tz = "UTC")
    
    return(secondData)
    
  })
  
  # データセットの列系統選択UIの出力 ----------------------------------------------------------
  output$selectDeps <- renderUI({
    # 列名labelは必要ないので除外
    Deplist = names(passData()[-1])
    
    selectInput(inputId = "theDeps", label = "トレンドグラフに描画する項目を指定してください（複数選択可）",
                Deplist, multiple = T, selected = Deplist[1])
  })
  
  
  
  # 選択された列系統と時刻ラベルを抽出したデータ --------------------------------------------------
  passData3 <- reactive({
    firstData <- passData2() %>% select(label, input$theDeps)
    
    return(firstData)
  })
  
  # ggplot用にデータをgather関数で形式変換したデータ ------------------------------------------
  passData4 <- reactive({
    firstData <- passData3() %>% tidyr::gather(input$theDeps, key = "Deps", value = "P_con")
    
    return(firstData)
  })
  
  #Gatherは複数の列を取得し、必要に応じて他のすべての列を複製してキーと値のペアに折りたたみます。
  passDatahm <- reactive({
    firstData <- 
      
      return(firstData)
  })
  # 選択された列系統と時刻ラベルを抽出したデータのテーブルの出力 ------------------------------------------
  output$DataTable <- renderDataTable({
    if (!is.null(input$file)) {
      datatable(passData3(),
                options = list(
                  lengthMenu = c(10, 100, 1500),
                  pageLength = 100,
                  width = 1000,
                  scrollX = "200px",
                  scrollY = "700px",
                  scrollCollapse = T
                ))
    } else {
      print(NULL)
    }
  })
  
  # クラスタリングしたい列系統のプルダウンUIの出力 ---------------------------------------------------
  output$target_cluster <- renderUI({
    # 列名labelは必要ないので除外
    Deplist = names(passData()[-1])
    
    selectInput(inputId = "target", label = "クラスタリングしたい項目を指定してください（複数選択不可）",
                Deplist, multiple = F, selected = Deplist[1])
  }) 
  
  # クラスタリング用の列系統を抽出したデータ ----------------------------------------------------
  targetData <- reactive({
    firstData <- passData() %>% select(label, input$target)
    Names <- names(firstData)
    repNA <- repOutliersNA(firstData[,2])
    # 外れ値をNAに置き換える
    secondData <- cbind.data.frame(firstData$label, repNA)
    names(secondData) <- Names
    NA_points <- length(which(is.na(secondData[,2])))
    # 補完
    if(NA_points != 0) {
      withProgress(message = "欠損値が見つかりました", detail = "Please wait...",
                   value = 1/2, {
                     secondData[[2]] <- na.interpolation(secondData[[2]], option = "linear")
                     incProgress(1/2)
                   })
      
    }
    
    return(secondData)
  })
  
  # 選択系列の最大値の情報ボックスの出力 ------------------------------------------------------
  output$Max <- renderInfoBox({
    if (!is.null(input$file)) {
      infoBox("選択系列の最大値", round(max(targetData()[[2]], na.rm = T), digits = 0), color = "red")
    } else {
      infoBox("選択系列の最大値", NULL, color = "red")
    }
    
  })
  
  # 選択系列の最小値の情報ボックスの出力 ------------------------------------------------------
  output$Min <- renderInfoBox({
    if (!is.null(input$file)) {
      infoBox("選択系列の最小値", round(min(targetData()[[2]], na.rm = T), digits = 0), color = "blue")
    } else {
      infoBox("選択系列の最小値", NULL, color = "blue")
    }
    
  })
  
  # 選択系列の平均値の情報ボックスの出力 ------------------------------------------------------
  output$Mean <- renderInfoBox({
    if (!is.null(input$file)) {
      infoBox("選択系列の平均値", round(mean(targetData()[[2]], na.rm = T), digits = 0), color = "green")
    } else {
      infoBox("選択系列の平均値", NULL, color = "green")
    }
    
  })
  
  # 選択系列のトレンドグラフの出力 ---------------------------------------------------------
  output$trendGragh <- renderPlot({
    if (!is.null(input$file)) {
      validate(
        need(input$theDeps != "", "項目を選択してください")
      )
      
      g1 <- ggplot(passData4(), aes(x = label, y = P_con, color = Deps)) + 
        geom_line() + ylim(input$RangeY[1], input$RangeY[2]) + xlab("時間") + ylab("電力消費量[kW]") + ggtitle("トレンドグラフ")
      
      data_heatmap <- passData4() %>% 
        mutate(day = as.Date(substr(label, 1, 10)),
               time = as.hms(substr(label, 12, 19)),
               week = format(as.POSIXct(label), "%W"),
               month = format(as.POSIXct(label), "%m"))
      
      data_heatmap$P_con[data_heatmap$P_con > input$RangeY[2]] <- NA
      
      
      # ヒートマップの出力 ---------------------------------------------------------------
      #output$heatm <- renderPlot({
      # uiからの情報を受け取るもの
      # if (!is.null(input$file)){
      gp <- ggplot(data = data_heatmap,aes(x = day, y = time, fill = P_con)) +
        #       geom_raster(aes_string(fill = P_con)) + scale_fill_gradient(low = "blue", high = "orange") +
        geom_raster() + scale_fill_gradient(low = "blue", high = "orange") +
        coord_cartesian(expand = F)
      # 出力
      
      #  } else {
      #    print(NULL)
      #  }
      #})
      
      
      
      ggg <- grid.arrange(g1,gp,nrow=2)
      print(ggg)
      
    } else {
      print(NULL)
    }
  })
  
  # クラスタリング用データの構築 ----------------------------------------------------------
  Data_qqq <- reactive({
    if(!is.null(input$file)) {
      # 対象列
      x <- targetData()[[2]] %>% data.frame()
      # NAがあってはならない
      validate(
        need(length(which(is.na(x))) == 0, "データの中に欠損値が含まれているので計算できません")
      )
      
      # 時間列
      tx <- targetData()[[1]]
      tx <- strptime(unlist(tx), "%Y-%m-%d %H:%M:%S")
      time <- format(tx, "%H:%M:%S")
      date <- format(tx, "%Y-%m-%d")
      date.day <- levels(factor(date))
      hour <- levels(factor(time))
      lab.date <- list(date.day, hour)
      y <- matrix(x[1:nrow(x),], ncol=24, byrow=TRUE, dimnames = lab.date)
      
      inital.v <- apply(y, 2, quantile, seq(0, 1, 1/7))
      
      kmean.y <- kmeans(y, inital.v[2:7,])
      centers <- kmean.y$centers
    } else {
      centers <- NULL
    }
    
    return(centers)
  })
  
  
  # クラスタセンタープロットに適した形式に変換 ---------------------------------------------------
  Data_qqq2 <- reactive({
    if (!is.null(input$file)) {
      tr <- t(Data_qqq())
      me <- melt(tr)
      mu<-mutate(me,cluster=paste0("cluster",me$Var2))
      
    } else {
      mu <- NULL
    }
    
    return(mu)
  })
  
  
  # クラスタセンタープロットの出力 ---------------------------------------------------------
  output$qqq <- renderPlot({
    if (!is.null(input$file)) {
      qqq <- ggplot(Data_qqq2(),aes(x=Var1,y=value,group=Var2,color=cluster))+geom_line(size=1.2)+
        theme(axis.text.x = element_text(angle = 90, hjust = 1)) + 
        xlab("時間") + ylab("電力消費量[kW]") + ggtitle("クラスタセンター")
      
      print(qqq)
    } else {
      print(NULL)
    }
  })
  
  # ヒートマップの作成 ---------------------------------------------------------------
  
  # data_heatmap <- dataset %>% 
  #   mutate(day = as.Date(substr(label, 1, 10)),
  #          time = as.hms(substr(label, 12, 19)),
  #          week = format(as.POSIXct(label), "%W"),
  #          month = format(as.POSIXct(label), "%m"))
  
  
  # # ヒートマップの出力 ---------------------------------------------------------------
  #   output$heatm <- renderPlot({
  #     # uiからの情報を受け取るもの
  #     if (!is.null(input$file)){
  #       gp <- ggplot(data = data_heatmap,aes(x = day, y = time)) +
  #         geom_raster(aes_string(fill = the_colname)) + scale_fill_gradient(low = "blue", high = "orange") +
  #         coord_cartesian(expand = F)
  #       # 出力
  #       print(gp)
  #     } else {
  #       print(NULL)
  #     }
  #   })
  
  # file=圧縮ファイル,URL,パイプなどの「一般化されたファイル」を作成,オープン,クローズする機能
  
})
