#' Get filepath information for a date and time.
#'
#' \code{getFilepaths} reads information from a settings file (csv) or a
#' settings list and returns the file paths and other information as a
#' dataframe. It undertakes a recursive search within the site folder for files
#' matching the date and time.
#'
#' @param settings Either a filepath to a settings file (csv) or a settings
#'     list. If a filepath, the filepath will first be passed to
#'     \code{\link{processSettings}}.
#' @param types Character, specifying the file type to be searched for. Either 'wav' or 'mp3'.
#' @return A data frame with station names, coordinates, filepaths, and any
#'     recording start-time adjustments.
#' @examples
#'     #Read example data
#'     settings <- read.csv(system.file('extdata',
#'                    'Ex_20200617_090000_Settings.csv', package = 'locaR'),
#'                    stringsAsFactors = FALSE)
#'
#'     #Over-write default values for SiteWavsFolder, CoordinatesFile, and ChannelsFile
#'     settings$Value[settings$Setting == 'SiteWavsFolder'] <-
#'                   system.file('extdata', package = 'locaR')
#'     settings$Value[settings$Setting == 'CoordinatesFile'] <-
#'                    system.file('extdata', 'Vignette_Coordinates.csv',
#'                                package = 'locaR')
#'     settings$Value[settings$Setting == 'ChannelsFile'] <-
#'                    system.file('extdata', 'Vignette_Channels.csv',
#'                                package = 'locaR')
#'
#'     #Run processSettings() function
#'     st <- processSettings(settings = settings, getFilepaths = FALSE)
#'
#'     #Get filepaths.
#'     fp <- getFilepaths(settings = st, types = 'mp3')
#' @export
getFilepaths <- function(settings, types = 'wav') {

  #Load settings to a list.
  if(is.character(settings)) {
    if(file.exists(settings)) {
      st <- processSettings(settings)
    }
  } else if(is.list(settings) & !is.data.frame(settings)) {
      st <- settings
  } else {
      stop('settings must be a filepath or a list')
  }

  #Change time to represent minutes rather than seconds.
  timeChar <- formatC(as.numeric(st$time), width = 6, flag = '0', format = 'd')
  minute <- substr(timeChar, 1, 4)


  #Load the files from that date and time.
  if(types == 'wav') {
    Files <- list.files(st$siteFolder, recursive = TRUE, full.names = TRUE,
                          pattern = paste0(st$date,'.*', minute, '.*wav'))
  }
  if(types == 'mp3') {
    Files <- list.files(st$siteFolder, recursive = TRUE, full.names = TRUE,
                        pattern = paste0(st$date,'.*', minute, '.*mp3'))
  }

  Files <- data.frame(Path = Files, Filename = basename(Files),
                      Station = parseWAFileNames(filenames = basename(Files))$prefix,
                      Difference = 0,
                      stringsAsFactors = FALSE)

  #remove extra mics
  if(nrow(st$channels) > 0) {
    extra <- Files$Station[!Files$Station %in% st$channels$Station]
    if(length(extra) > 0) {
      Files <- Files[!Files$Station %in% extra,]
      warning(paste0('Removing files from ', paste(extra), ' not found in channels file.\n'))
    }

    #Add missing files if needed.
    missing <- st$channels$Station[!st$channels$Station %in% Files$Station]
    if(length(missing) > 0) {
      mdf <- data.frame(Path=NA, Filename=NA, Station=missing, Difference = NA)
      Files <- rbind(Files, mdf)
      Files <- Files[order(Files$Station),]
      warning(paste0('No file found for ', paste(missing), '. Adding placeholders to file list.\n'))
    }
  }

  #Get adjustment for each file. This is using the filename-based adjustment relative to the
  #stated survey start time.
  Files$Adjustment <- as.numeric(parseWAFileNames(Files$Filename)$time) - as.numeric(st$time)

  #Then add any difference relative to the file name (i.e. if the file name is wrong). Here we are
  #comparing the files listed to the adjustments files.
  if(!all(is.na(st$adjustments))) {
    for(i in 1:nrow(Files)) {
      if(Files$Filename[i] %in% st$adjustments$Filename) {
        Files$Difference[i] <- st$adjustments$Difference[st$adjustments$Filename == Files$Filename[i]]
      }
    }
  }

  #Add Difference to existing Adjustment.
  Files$Adjustment <- Files$Adjustment + Files$Difference

  Files <- merge(Files, st$coords, by='Station')

  #Strip unnecessary columns.
  Files <- Files[,colnames(Files) %in% c('Station', 'Path', 'Filename', 'Adjustment', 'Zone', 'Easting',
                                         'Northing', 'Elevation')]

  #Merge with channels data. If Channels not specified, default to 1.
  if(nrow(st$channels) > 0) {
    Files$Channel <- merge(Files, st$channels, by='Station')$Channel
  } else {
    Files$Channel = 1
  }

  #Return dataframe containing files and metadata.
  return(Files)

}
