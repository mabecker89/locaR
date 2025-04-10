% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/localize.R
\name{localize}
\alias{localize}
\alias{localizeMultiple}
\title{Localize detected sounds}
\usage{
localize(
  wavList,
  coordinates,
  margin = 10,
  zMin = -1,
  zMax = 20,
  resolution = 1,
  F_Low = 2000,
  F_High = 8000,
  tempC = 15,
  soundSpeed,
  plot = TRUE,
  locFolder,
  jpegName = "000.jpeg",
  InitData = NULL,
  keep.InitData = TRUE,
  keep.SearchMap = FALSE
)

localizeMultiple(st, indices = "all", plot = TRUE, InitData = NULL)
}
\arguments{
\item{wavList}{list of Wave objects. The name of the Wave objects MUST be
present in the coordinates data.frame.}

\item{coordinates}{data.frame. Must contain four required columns:
column Station contains a character string with names of each recording
station, while Easting, Northing and Elevation contain the x, y, and z
coordinates of the station, in meters (E.g. UTM coordinates).}

\item{margin, zMin, zMax, resolution}{Arguments describing the area to be searched
for sound sources. Passed to \code{\link{makeSearchMap}}.}

\item{F_Low, F_High}{Numeric. The low and high frequency, in Hz, of the sound
to be localized.}

\item{tempC}{Numeric. Temperature in degrees C, which is used to calculate
the speed of sound in air using the equation 331.45*sqrt(1+tempC/273.15).}

\item{soundSpeed}{Numeric. The speed of sound in meters per second. If missing,
the speed of sound is calculated based on the specified
temperature (assuming the transmission medium is air). If soundSpeed is
specified, the tempC value is over-ridden.}

\item{plot}{Logical. Whether to plot jpegs.}

\item{locFolder}{Character. File path to the folder where localization jpegs
(heatmaps and spectrograms) are to be created. Only required if plot = TRUE.}

\item{jpegName}{Character. Name of the jpeg, ending in extension .jpeg.
Only required if plot = TRUE.}

\item{InitData}{List. An InitData list created by running localization with
keep.InitData = TRUE. Providing an InitData list saves computation time,
but is only possible if the SearchGrid and stations used for localization
remain unchanged. Default is NULL, which means the InitData will be
calculated anew.}

\item{keep.InitData}{Logical. Whether to store the InitData list.}

\item{keep.SearchMap}{Logical. Whether to keep the SearchMap list with
power estimates and coordinates of each grid cell.
Should only be set to TRUE if the SearchMap is needed
for some other reason (e.g. making a publication-ready figure or
conducting more involved analysis with overlapping sources, etc.).}

\item{st}{List. Localization settings object generated using
\code{\link{processSettings}}. Only needed for \code{localizeSingle} or
\code{localizeMultiple}.}

\item{indices}{Numeric or 'all'. Indices to be localized within a detection file.
Setting to 1 localizes the first row, c(7:10) localizes rows 7-10, and 'all'
localizes all rows (ignoring rows that have no entry in the Station1 column).}
}
\value{
List, containing the location of the sound source (global maximum),
    and optionally the InitData and SearchMap lists.
}
\description{
\code{localize} and the related function \code{localizeMultiple}
are the basic functions for localizing sounds. They take audio data as inputs, alongside relevant
 metadata (e.g. coordinates and a variety of settings), and estimate the location of the
 dominant sound source. The \code{localize} function takes as arguments the minimal
amount of information needed for localization. Localization is conducted on the
full duration of the Wave objects in wavList. Effectively this means the user
must wrangle the data and clip the audio themselves, but this affords the greatest
flexibility in terms of how the user chooses to organize their data.
The \code{localizeMultiple} function, in contrast,
automates much of the data wrangling process, but requires data to be organized in a
very specific way (e.g. folder structure, file structures). Thus, the latter
function trades off flexibility for increased automation. Both functions use the
same underlying localization algorithm - \code{localizeMultiple}
passes its data to \code{localize} after the data has been wrangled.
}
\examples{
    \donttest{
    ## example for localize()
    #Get filepaths for example data.
    fp <- list.files(system.file('extdata', package = 'locaR'), pattern = '.mp3', full.names = TRUE)
    #Add names.
    names(fp) <- sapply(strsplit(basename(fp), '_'), '[[', 1)
    #Load first row of detection data.
    row <- read.csv(system.file('extdata',
         'Vignette_Detections_20200617_090000.csv', package = 'locaR'),
          stringsAsFactors = FALSE)[1,]
    #Get non-empty Station columns.
    stationSubset <- unlist(row[1,paste0('Station',1:6)])
    stationSubset <- stationSubset[!is.na(stationSubset) & stationSubset != '']
    #Create wav list.
    wl <- createWavList(paths = fp[stationSubset], names = stationSubset,
           from = row$From, to = row$To, buffer = 0.2, index=1)
    #Read coordinates.
    coordinates <- read.csv(system.file('extdata', 'Vignette_Coordinates.csv',
                                        package = 'locaR'), stringsAsFactors = FALSE)
    row.names(coordinates) <- coordinates$Station
    #Subset coordinates.
    crd <- coordinates[stationSubset,]
    #Localize.
    loc <- localize(wavList = wl, coordinates = crd, locFolder = tempdir(),
               F_Low = row$F_Low, F_High = row$F_High,
               jpegName = '0001.jpeg', keep.SearchMap = TRUE)

    ## Example for localizeMultiple().
    #list mp3 files.
    f.in <- list.files(system.file('extdata', package = 'locaR'), full.names = TRUE, pattern='mp3$')
    #create wav names.
    f.out <- file.path(tempdir(), basename(f.in))
    #change extension.
    substr(f.out, nchar(f.out)-2, nchar(f.out)) <- 'wav'
    #Convert mp3 to wav, as required for this particular example.
    for(i in 1:length(f.in)) {
      y <- tuneR::readMP3(f.in[i])
      tuneR::writeWave(y, filename = f.out[i])
    }
    #Set up survey.
    survey <- setupSurvey(folder = tempdir(), projectName = 'Ex', run = 1,
               coordinatesFile = system.file('extdata', 'Vignette_Coordinates.csv',
                                             package = 'locaR'),
               siteWavsFolder = tempdir(), date = '20200617', time = '090000', surveyLength = 7)
    #read example detections.
    dets <- read.csv(system.file('extdata', 'Vignette_Detections_20200617_090000.csv',
                                 package = 'locaR'))
    #over-write empty detections file.
    write.csv(dets, file.path(tempdir(), '20200617_090000',
              'Run1', 'Ex_20200617_090000_Run1_Detections.csv'), row.names = FALSE)
    #Process settings.
    st <- processSettings(settings = survey, getFilepaths = TRUE, types = 'wav')
    #localize
    locs <- localizeMultiple(st = st, indices = 1:2)
    }
}
\references{
Cobos, M., Martí, A., & J.J. López. 2011. A modified SRP-PHAT functional for robust real-time sound source localization with scalable spatial sampling. IEEE Signal Processing Letters. 18:71-74. doi:10.1109/LSP.2010.2091502.
}
