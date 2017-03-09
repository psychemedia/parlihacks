#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)

gcode="E06000046"
la='Isle of Wight'

fp='/Users/ajh59/Downloads/Broadband---Constituency-and-Ward-tables'
#Alternatively, we could load it in directly from the CSV URL
df = read_excel (paste0(fp,'.xlsx'), sheet = 'Ward Data', skip=2)
df = df<-df[3:(dim(df)[1]-14),] #drop top two rows and last 5
write.csv(df,paste0(fp,'csv'))
df = read.csv (paste0(fp,'csv'))

library(rgdal)
gdata=paste0("/Users/ajh59/Dropbox/onthewight/IWgeodata/wards_by_lad/", gcode, ".json")
geoj= readOGR( gdata, "OGRGeoJSON", verbose = FALSE) # The verbose switch prevents printing of read diagnostics

thisConstituency= as.data.frame(df[df['Local.Authority'] ==la,])
cols=names(thisConstituency)[! names(thisConstituency) %in% c("Ward.Code", "Ward.Name","Constituency" ,
                                                              "Local.Authority","Region..Country","X")]

# Define UI for application that draws a histogram
ui <- fluidPage(
   
   # Application title
   titlePanel("IW Broadband Mapper"),
   
   # Sidebar with a slider input for number of bins 
   sidebarLayout(
      sidebarPanel(
         selectInput("ptype",
                     "Report type:",
                     cols
                     )
      ),
      
      # Show a plot of the generated distribution
      mainPanel(
         plotOutput("mapPlot"),
         dataTableOutput('table')
      )
   )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
   
   library(rgeos)
   #requires maptools, mapproj
   library(ggplot2)
   library(plyr)
   
   #We need to make sure the data is presented in the correct format...
   #The codes we want to map against in the boundary file are in the LSOA11CD column
   geojf = fortify(geoj, region = "WD13CD")
   
   #Plot the map as a choropleth map using the ggplot geom_map geom.
   #The aesthetic identfies the column in the data file that identifies the boundary area code
   #Use two geom_maps - one to render *all* the boundaries in the area...
   output$mapPlot = renderPlot( {
     ptype=input$ptype
     thisConstituency[[ptype]]=as.numeric(thisConstituency[[ptype]])
     g = ggplot() + geom_map(
       data = thisConstituency,
       aes(map_id = Ward.Code),
       map = geojf,
       fill = 'lightgrey'
     )
     
     # the other to render the choropleth areas
     g = g + geom_map(data = thisConstituency, aes_string(map_id = "Ward.Code", fill = ptype), map = geojf)
     #If we omit the first geom_map, only the boundaries of areas associated with the data file will be plotted
     
     #Set the zoom scale so we can see all the rendered boundaries
     g = g + expand_limits(x = geojf$long, y = geojf$lat)  + coord_map()
     
     g=g+ggtitle(ptype)
     
     g=g+theme(axis.line=element_blank(),axis.text.x=element_blank(),
               axis.text.y=element_blank(),axis.ticks=element_blank(),
               axis.title.x=element_blank(),
               axis.title.y=element_blank(),
               panel.background=element_blank(),panel.border=element_blank(),panel.grid.major=element_blank(),
               panel.grid.minor=element_blank(),plot.background=element_blank()) + labs(fill="")
     
     #Display the map
     g
   })
   
   output$table = renderDataTable({
     ptype=input$ptype
     thisConstituency[,c('Ward.Name',ptype)]
     })
}

# Run the application 
shinyApp(ui = ui, server = server)

