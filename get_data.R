# this script builds the data from the UFO sightings database
# hosted at nuforc.org. All data belongs to them!

library(magrittr)
library(httr)
library(RCurl)
library(rvest)
library(lubridate)
library(plyr)

remove_crap <- function(a_page){
  # pages are invalid HTML, so need to grab them and pull out
  # just the table
  start_crap <- "^<HTML>\r\n<HEAD>\r\n<META.*</HEAD>\r\n<BODY>\r\n"
  end_crap <- "\\r\\n</BODY>\\r\\n</HTML>\\r\\n$"
  table_only <- sub(end_crap, "", a_page)
  table_only <- sub(start_crap, "", table_only)

  return(table_only)
}

get_events <- function(){
  url <- "http://www.nuforc.org/webreports/ndxevent.html"
  a_page <- RCurl::getURL(url)
  table_only <- remove_crap(a_page)
  this_tab <- html_table(read_html(table_only))
  return(this_tab[[1]])
}

get_event_pages <- function(){
  url <- "http://www.nuforc.org/webreports/ndxevent.html"
  a_page <- RCurl::getURL(url)
  table_only <- remove_crap(a_page)
  pages <- read_html(table_only) %>% html_nodes("a") %>% html_attr("href")
  pages <- paste0("http://www.nuforc.org/webreports/", pages)
  return(pages)
}


# retrieve the events to check number of entries against
events <- get_events()

# get pages
event_urls <- get_event_pages()

# make get the table for a given url
event_table <- function(url){
  a_page <- RCurl::getURL(url)
  table_only <- remove_crap(a_page)
  this_tab <- html_table(read_html(table_only))
  return(this_tab[[1]])
}


ttt <- ldply(event_urls, event_table)

# interpret the date
ttt$Date <- mdy_hm(ttt[["Date / Time"]])
# for those that failed to parse
ttt$Date[is.na(ttt$Date)] <- mdy(ttt[["Date / Time"]][is.na(ttt$Date)])
ttt[["Date / Time"]] <- NULL

# interpret the posted date
ttt$Posted <- mdy(ttt[["Posted"]])

ufos <- ttt


# save that!
save(ufos, file="ufos.RData")
