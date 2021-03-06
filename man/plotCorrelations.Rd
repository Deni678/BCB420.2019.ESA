% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plotCorrelations.R
\name{plotCorrelations}
\alias{plotCorrelations}
\title{\code{plotCorrelations()} Plots co-expression and functional correlations.}
\usage{
plotCorrelations(bioSys, coExpFile = NULL, semSimFile = NULL,
  coExpVsSemFile = NULL, pShape = 16)
}
\arguments{
\item{bioSys}{Biological system symbol.}

\item{coExpFile}{file name for the functional correlation
graph. If not specified (NULL - default) the graph will be shown on screen. Supported file formats - pdf and png}

\item{semSimFile}{if specified - will dave the semantic similarity
correlation graph to file. Supported formats - pdf and png}

\item{coExpVsSemFile}{if sepcified - will save the functional correlation
vs semantic similarity correlation to file. Supported formats - see ggsave.}

\item{pShape}{shape of the points in the functional vs co-expression
graph. Example values - 1,16,22,23 etc. See ggplot.}
}
\value{
(list) ggplot graph.
}
\description{
\code{plotCorrelations()} Calculates pairwise co-expression Correlation
between expression profiles of genes in input system bioSys and pairwise
Semantic Similarity correlation between GO terms of genes in input system bioSys
levels and one plot to charcaterize the orthogonal relationship
between genes in the system.
}
\examples{
\dontrun{
plotCorrelations("PHALY")
## plots pairwise co-expression correlation graph, semantic
## similarity correlation graph and functional vs co-expression correlation
## graphs and returns the latter as ggplot list
}
\dontrun{
plotCorrelations("PHALY", coExpFile = "somefile.pdf") ## save co-expression correlation graph
## correlation graph into file 'somefile.pdf', and plots similarity correlation
## graph and functional vs co-expression correlation graphs and returns the
## latter as ggplot list
}
}
\references{
H. Wickham. ggplot2: Elegant Graphics for Data Analysis. Springer-Verlag New York, 2016.

\href{https://cran.r-project.org/web/packages/corrplot/vignettes/corrplot-intro.html}{corrplot package}
}
\author{
\href{https://orcid.org/0000-0002-8778-6442}{Denitsa Vasileva} (aut)
}
