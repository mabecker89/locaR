% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/localizeSingle.R
\name{localizeSingle}
\alias{localizeSingle}
\title{Localize detected sounds}
\usage{
localizeSingle(
  st,
  index,
  plot = TRUE,
  InitData = NULL,
  keep.InitData = TRUE,
  keep.SearchMap = FALSE
)
}
\arguments{
\item{st}{List. Localization settings object generated using
\code{\link{processSettings}}.}

\item{index}{Numeric. Index to be localized within a detection file.}

\item{plot}{Logical. Whether to plot jpegs.}

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
}
\value{
List, containing the location of the sound source (global maximum),
    and optionally the InitData and SearchMap lists.
}
\description{
\code{localizeSingle} is an internal function implemented within \code{localizeMultipe}. Its basic function is to take an index value corresponding to a detection, extract that detection, extract the relevant coordinates, and feed all relevant metadata into the `localize()` function.
}
