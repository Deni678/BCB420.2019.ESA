#' \code{preDraw} Helper function.
#' Helper function for the co-expression correlation and semantic similarity correllation heat maps
#' @param fileName (character)     if not NULL - it will use the Cairo package to create a
#'                                 device. It checks the file extension to
#'                                 instantiate appropriate device;
#'                                 otherwise - it does nothing (graphs are plotted on screen)
#' @return (NULL)
#' @author \href{https://orcid.org/0000-0002-8778-6442}{Denitsa Vasileva} (aut)
#' [Cairo package](https://CRAN.R-project.org/package=Cairo
preDraw <- function(fileName) {
  if (is.null(fileName)) {
    return(invisible(NULL))
  }
  # is the file extension pdf?
  if (grepl(".pdf$", fileName)) {
    Cairo::CairoPDF(
      file = fileName,
      width = 1920,
      height = 1080,
      res = 92,
      pointsize = 12
    )
    return(invisible(NULL))
  }
  # otherwise - default to png
  if (!grepl(".png$", fileName)) {
    fileName <- paste0(fileName, ".png")
  }
  # Cairo Package https://CRAN.R-project.org/package=Cairo
  Cairo::CairoPNG(
    file = fileName,
    width = 1920,
    height = 1080,
    res = 92,
    pointsize = 12
  )
  return(invisible(NULL))
}

#' Helper function for the co-expression correlation & semantic similarity correlation heat maps
#' @param fileName - if not NULL - it will call dev.off to save the file
#' otherwise - it prompts for user input - so the user can see the graph
#' before the next one is drawn
#' @return (NULL)
#' @author \href{https://orcid.org/0000-0002-8778-6442}{Denitsa Vasileva} (aut)
postDraw <- function(fileName) {
  if (is.null(fileName)) {
    readline(prompt = "Press enter to continue...")
  } else {
    dev.off()
  }
  return(invisible(NULL))
}


#'
#' \code{installHumanGenomeAnnotation()} installs Human Genome Annotation
#' as per Dr. Stipe's email and
#' https://bioconductor.org/packages/release/data/annotation/html/org.Hs.eg.db.html
#'
installHumanGenomeAnnotation <- function() {
  if (!requireNamespace("BiocManager", quietly = TRUE)) {
    install.packages("BiocManager")
  }
  BiocManager::install("org.Hs.eg.db", version = "3.8")
  return(invisible(NULL))
}

#'
#' \code{computeCorrelations()} Calculates pairwise Semantic similarity and co-expression correlation
#' between expression profiles of genes and returns a
#' data frame
#'
#' @author \href{https://orcid.org/0000-0002-8778-6442}{Denitsa Vasileva} (aut)
#' @param silent = FALSE suppresses all messages when TRUE
#' @return (data frame)           containing gene A, gene B, correlation between them and
#'                                GOSemSim correlation
#' [GOSemSim package](http://bioconductor.org/packages/release/bioc/html/GOSemSim.html)
#' [org.Hs.eg.db data package](https://bioconductor.org/packages/release/data/annotation/html/org.Hs.eg.db.html)
computeCorrelations <- function(silent = FALSE) {
  sysDB <- fetchData("SysDB")

  # Dr.Steipe's data file
  geoQNURL <- paste0(
    "http://steipe.biochemistry.utoronto.ca/abc/assets/",
    "GEO-QN-profile-2019-03-24.rds")

  geoQNXP <- readRDS(url(geoQNURL))
  if (!silent) {
    cat(sprintf("Loading GO - genome wide annotation for human.\n"))
  }
  installHumanGenomeAnnotation()
  hsGO <- GOSemSim::godata("org.Hs.eg.db", keytype = "SYMBOL", ont = "MF")
  if (!silent) {
    cat(sprintf("%d rows loaded.\n", nrow(hsGO)))
  }
  systemV <- vector(mode = "character", length = 0)
  gene1V <- vector(mode = "character", length = 0)
  gene2V <- vector(mode = "character", length = 0)
  correlationV <- vector(mode = "numeric", length = 0)
  goCorrelationV <- vector(mode = "numeric", length = 0)
  for (bioSystem in c("PHALY", "SLIGR", "NLRIN")) {
    systemComponents <- SyDBgetSysSymbols(sysDB, bioSystem)[[1]]
    componentsCount <- length(systemComponents)
    if (!silent) {
      cat(sprintf("\nComputing correlations between %s genes:", bioSystem))
    }
    for (c1 in 1:componentsCount) {
      for (c2 in c1:componentsCount) {
        gene1 <- systemComponents[c1]
        gene2 <- systemComponents[c2]
        if (c1 != c2) {
          prf1 <- as.numeric(geoQNXP[gene1, ])
          prf2 <- as.numeric(geoQNXP[gene2, ])
          cCorr <- cor(prf1, prf2, use = "pairwise.complete.obs")
          cGO <- GOSemSim::geneSim(gene1,
            gene2,
            semData = hsGO,
            measure = "Wang",
            combine = "BMA"
          )[[1]]
        } else { # the same gene
          cCorr <- 1
          cGO <- 1
        }
        gene1V <- c(gene1V, gene1)
        gene2V <- c(gene2V, gene2)
        correlationV <- c(correlationV, cCorr)
        goCorrelationV <- c(goCorrelationV, cGO)
        systemV <- c(systemV, bioSystem)
      }
      if (!silent) {
        cat(sprintf("."))
      }
    }
  }
  if (!silent) {
    cat(sprintf("\n"))
  }

  df <- data.frame(systemV, gene1V, gene2V, correlationV, goCorrelationV)
  colnames(df) <- c("System", c("gene1", "gene2", "correlation", "goCorrelation"))
  return(df)
}

#'
#' Calculates correlations for the test case. The test case is designed to
#' calculate the data correctness in the data frame generated by
#' computeCorrelations(). This helper counts the records in the
#' data frame that belong to bioSys and sums-up the correlation and
#' semantic simulation columns.
#' Those values are later compared in the test cases with pre-calculated values
#' @author \href{https://orcid.org/0000-0002-8778-6442}{Denitsa Vasileva} (aut)
#' @param dframe - the source data frame
#' @param bioSys - name of the system (PHALY, SLIGR or NLRIN)
#' @return (list) ## which contains record counts, control sum of the correlation
#' and sem sim correlation for all records that belong to a System
#' in the data frame
calcStats <- function(dframe, bioSys) {
  d <- dframe[dframe$System == bioSys, ]
  corrSum <- sum(d$correlation, na.rm = TRUE)
  goCorrSum <- sum(d$goCorrelation, na.rm = TRUE)
  recCount <- nrow(d)
  return(list(recCount = recCount, corrSum = corrSum, goCorrSum = goCorrSum))
}

#'
#' \code{plotCorrelations()} Plots co-expression and functional correlations.
#'
#' \code{plotCorrelations()} Calculates pairwise co-expression Correlation
#' between expression profiles of genes in input system bioSys and pairwise
#' Semantic Similarity correlation between GO terms of genes in input system bioSys
#  and returns a list of two heat maps representing the two correlation
#' levels and one plot to charcaterize the orthogonal relationship
#' between genes in the system.
#'
#'
#' @param bioSys Biological system symbol.
#' @param coExpFile file name for the functional correlation
#' graph. If not specified (NULL - default) the graph will be shown on screen. Supported file formats - pdf and png
#' @param semSimFile if specified - will dave the semantic similarity
#' correlation graph to file. Supported formats - pdf and png
#' @param  coExpVsSemFile if sepcified - will save the functional correlation
#' vs semantic similarity correlation to file. Supported formats - see ggsave.
#' @param  pShape shape of the points in the functional vs co-expression
#' graph. Example values - 1,16,22,23 etc. See ggplot.
#' @return (list) ggplot graph.
#'
#' @author \href{https://orcid.org/0000-0002-8778-6442}{Denitsa Vasileva} (aut)
#' @references H. Wickham. ggplot2: Elegant Graphics for Data Analysis. Springer-Verlag New York, 2016.
#' @references \href{https://cran.r-project.org/web/packages/corrplot/vignettes/corrplot-intro.html}{corrplot package}
#' @examples
#' \dontrun{
#' plotCorrelations("PHALY")
#' ## plots pairwise co-expression correlation graph, semantic
#' ## similarity correlation graph and functional vs co-expression correlation
#' ## graphs and returns the latter as ggplot list
#' }
#' @examples
#' \dontrun{
#' plotCorrelations("PHALY", coExpFile = "somefile.pdf") ## save co-expression correlation graph
#' ## correlation graph into file 'somefile.pdf', and plots similarity correlation
#' ## graph and functional vs co-expression correlation graphs and returns the
#' ## latter as ggplot list
#' }
#' @export
plotCorrelations <- function(bioSys,
                             coExpFile = NULL,
                             semSimFile = NULL,
                             coExpVsSemFile = NULL,
                             pShape = 16) {
  sdf <- computeCorrelations()
  if (!bioSys %in% sdf$System) {
    stop("Unknown system passed as parameter.")
  }

  # Convert the data frame to a symmetrix matrix (required by corrplot)
  sysDF <- sdf[
    sdf$System == bioSys,
    c("gene1", "gene2", "correlation", "goCorrelation")
  ]

  geneCount <- length(unique(sysDF$gene1))
  coM <- matrix(nrow = geneCount, ncol = geneCount)
  goM <- matrix(nrow = geneCount, ncol = geneCount)
  colnames(coM) <- unique(sysDF$gene1)
  rownames(coM) <- unique(sysDF$gene2)
  colnames(goM) <- unique(sysDF$gene1)
  rownames(goM) <- unique(sysDF$gene2)
  for (i in 1:nrow(sysDF)) {
    coM[
      as.character(sysDF$gene1[i]),
      as.character(sysDF$gene2[i])
    ] <- as.numeric(sysDF$correlation[i])
    coM[
      as.character(sysDF$gene2[i]),
      as.character(sysDF$gene1[i])
    ] <- as.numeric(sysDF$correlation[i])
    goM[
      as.character(sysDF$gene1[i]),
      as.character(sysDF$gene2[i])
    ] <- as.numeric(sysDF$goCorrelation[i])
    goM[
      as.character(sysDF$gene2[i]),
      as.character(sysDF$gene1[i])
    ] <- as.numeric(sysDF$goCorrelation[i])
  }
  # R requires Cairo package - in order to save the image to file
  # Check if the package is installed and if not - default to screen
  if (!"Cairo" %in% rownames(installed.packages())) {
    if (!is.null(coExpFile) || !is.null(semSimFile) || !is.null(coExpVsSemFile)) {
      message("Saving graphs to file requires Cairo pckg. Defaulting to screen.")
      coExpFile <- NULL
      semSimFile <- NULL
      coExpVsSemFile <- NULL
    }
  }

  # Plot the correlation in a file (if file name specified)
  # otherwsie - plot to R Console's canvas
  cat(sprintf("Plotting Pairwise Co-Expression Correlation...\n"))
  preDraw(coExpFile)
  corrplot::corrplot(as.matrix(coM),
    type = "upper",
    order = "original",
    tl.cex = 0.5,
    diag = TRUE,
    title = "Pairwise Co-Expression Correlation",
    col = RColorBrewer::brewer.pal(n = 8, name = "RdYlBu"),
    mar = c(0, 0, 1, 0)
  )
  postDraw(coExpFile)

  # Plot the correlation in a file (if file name specified)
  # otherwsie - plot to R Console's canvas
  cat(sprintf("Plotting Pairwise Semantic Similarity Correlation...\n"))
  preDraw(semSimFile)
  corrplot::corrplot(goM,
    type = "upper",
    order = "original",
    tl.cex = 0.5,
    diag = TRUE,
    na.label = "N",
    na.label.col = "white",
    title = "Pairwise Semantic Similarity Correlation",
    col = RColorBrewer::brewer.pal(n = 8, name = "RdYlBu"),
    mar = c(0, 0, 1, 0)
  )
  postDraw(semSimFile)

  cat(sprintf("Plotting semantic similarity vs co-expression correlation...\n"))
  title <- paste0("Semantic Similarity Correlation vs Co-Expression Correlation ", bioSys)
  cols <- c("PHALY" = "darkgrey", "SLIGR" = "grey", "NLRIN" = "grey")
  cols[bioSys] <- "darkgreen"

  sdf$ord <- ifelse(sdf$System == bioSys, 2.5, 1.5)
  sdf <- sdf[order(sdf$ord), ]

  graph <- ggplot2::ggplot(data = sdf) +
    ggplot2::geom_point(
      ggplot2::aes(x = goCorrelation, y = correlation, colour = System),
      shape = pShape, # 16, #1,
      size = 2.0,
      na.rm = TRUE
    ) +
    ggplot2::ggtitle(title) +
    ggplot2::theme_bw() +
    ggplot2::scale_color_manual(values = cols) +
    ggplot2::scale_x_continuous(name = "Semantic similarity") +
    ggplot2::scale_y_continuous(name = "Co-expression correlation")

  print(graph)

  if (!is.null(coExpVsSemFile)) {
    ggplot2::ggsave(filename = coExpVsSemFile)
  }
  return(graph)
}
#END
