# L2P Analysis for Single Comparisons [CCBR] - Version 148
# Extracted from NIDAP template: ri.vector.main.template.ff44bcce-10c1-4147-a089-79cadc4ea68a
# Description: Over-representation analysis using l2p for up/down regulated gene lists

utils::globalVariables(c(
    "allgenesinpw",
    "category",
    "enrichment_score",
    "fdr",
    "genesinpathway",
    "number_hits",
    "pathway_name",
    "pathwayname2",
    "percent_gene_hits_per_pathway",
    "pval",
    "color",
    "size",
    "sort",
    "analysis_prefix",
    "new_gene_names",
    "species"
))

#' L2P Analysis for Single Comparisons [CCBR]
#'
#' Reproduce the CCBR/NIDAP "L2P Analysis for Single Comparisons" template
#' (version 148). Given a differential expression table, the routine selects
#' up- and down-regulated gene lists using either rank- or threshold-based
#' criteria, runs l2p pathway enrichment, and renders bar/bubble plots along
#' with a combined pathway table.
#'
#' @param deg_table Data frame containing differential expression statistics.
#' @param gene_name_column Character string naming the gene identifier column.
#' @param species Character string specifying the organism (default "Human").
#' @param collections_to_include Character vector of pathway collections to
#'   include in l2p.
#' @param select_by_rank Logical; when `TRUE`, select genes by ranking.
#' @param column_used_to_rank_genes Character vector; the first element denotes
#'   the ranking column.
#' @param select_top_percentage_of_genes Logical; when `TRUE`, take the top 10%
#'   of ranked genes, otherwise use `select_top_genes`.
#' @param select_top_genes Integer number of top genes to use when
#'   `select_top_percentage_of_genes` is `FALSE`.
#' @param significance_column Character vector; the first element names the
#'   p-value column used when `select_by_rank = FALSE`.
#' @param significance_threshold Numeric significance threshold.
#' @param fold_change_column Character vector; the first element names the fold
#'   change column used when `select_by_rank = FALSE`.
#' @param fold_change_threshold Numeric fold-change threshold (linear scale).
#' @param minimum_number_of_DEG_genes Integer minimum gene count required for
#'   enrichment analysis.
#' @param number_of_pathways_to_plot Integer number of pathways to display in
#'   plots.
#' @param plot_top_pathways_up Logical; when `TRUE`, automatically select top
#'   upregulated pathways, otherwise use `pathways_to_use_up`.
#' @param pathways_to_use_up Character vector of pathways to display when
#'   `plot_top_pathways_up = FALSE`.
#' @param plot_top_pathways_down Logical; when `TRUE`, automatically select top
#'   downregulated pathways, otherwise use `pathways_to_use_down`.
#' @param pathways_to_use_down Character vector of pathways to display when
#'   `plot_top_pathways_down = FALSE`.
#' @param pathway_axis_label_font_size Numeric axis label font size for plots.
#' @param pathway_axis_label_max_length Integer maximum label length (wrapped).
#' @param sort_bubble_plot_by Character string describing bubble plot ordering.
#' @param plot_bubble_size Character string naming the metric mapped to bubble
#'   size.
#' @param plot_bubble_color Character string naming the metric mapped to bubble
#'   colour.
#' @param bubble_colors Character string specifying the colour palette.
#' @param use_fdr_pvals Logical; when `TRUE`, use FDR values in bar plots.
#' @param color_for_bar Character string specifying the bar plot palette.
#' @param use_built_in_gene_universe Logical; when `TRUE`, rely on l2p's built-in
#'   universe.
#' @param minimum_pathway_hit_count Integer minimum pathway hit count.
#' @param maximum_pathway_hit_count Integer maximum pathway hit count (use `Inf`
#'   for no upper bound).
#' @param p_value_threshold_for_output Numeric pathway p-value cutoff.
#' @param plot_bubble Logical; when `TRUE`, draw bubble plots.
#'
#' @return Data frame of enriched pathways (or `NULL` when none qualify). The
#'   plots are printed to the active graphics device as in the original template.
#'
L2P_Single <- function(deg_table,
                       gene_name_column,
                       species = "Human",
                       collections_to_include = c("GO", "REACTOME", "KEGG"),
                       select_by_rank = TRUE,
                       column_used_to_rank_genes = NULL,
                       select_top_percentage_of_genes = TRUE,
                       select_top_genes = 500,
                       significance_column = NULL,
                       significance_threshold = 0.05,
                       fold_change_column = NULL,
                       fold_change_threshold = 1.2,
                       minimum_number_of_DEG_genes = 50,
                       number_of_pathways_to_plot = 12,
                       plot_top_pathways_up = TRUE,
                       pathways_to_use_up = character(),
                       plot_top_pathways_down = TRUE,
                       pathways_to_use_down = character(),
                       pathway_axis_label_font_size = 15,
                       pathway_axis_label_max_length = 50,
                       sort_bubble_plot_by = "percent gene hits per pathway",
                       plot_bubble_size = "number of hits",
                       plot_bubble_color = "Fisher's Exact pval",
                       bubble_colors = "blues",
                       use_fdr_pvals = FALSE,
                       color_for_bar = "GreentoBlue",
                       use_built_in_gene_universe = FALSE,
                       minimum_pathway_hit_count = 5,
                       maximum_pathway_hit_count = 200,
                       p_value_threshold_for_output = 0.05,
                       plot_bubble = TRUE) {
    ## --------- ##
    ## Libraries ##
    ## --------- ##

    suppressPackageStartupMessages({
        library(dplyr)
        library(magrittr)
        library(ggplot2)
        library(stringr)
        library(RCurl)
        library(grid)
        library(l2p)
        library(l2psupp)
    })

    ## -------------------------------- ##
    ## Parameter preparation (template) ##
    ## -------------------------------- ##

    column_used_to_rank_genes <- column_used_to_rank_genes[1]
    significance_column <- significance_column[1]
    fold_change_column <- fold_change_column[1]

    ## --------------- ##
    ## Error Messages ##
    ## -------------- ##

    if ((plot_top_pathways_up == FALSE && length(pathways_to_use_up) == 0) ||
        (plot_top_pathways_down == FALSE && length(pathways_to_use_down) == 0)) {
        stop("ERROR: Enter at least one pathway in 'Pathways to use' when 'Plot top pathways' is set to FALSE")
    }
    if ((plot_top_pathways_up == TRUE && length(pathways_to_use_up) > 0) ||
        (plot_top_pathways_down == TRUE && length(pathways_to_use_down) > 0)) {
        stop("ERROR: Remove pathways from 'Pathways to use' when 'Plot top pathways' is set to TRUE")
    }
    if (select_by_rank == FALSE) {
        sigcol <- gsub("_pval|p_val_|_adjpval|p_val_adj_", "", significance_column)
        fccol <- gsub("_FC|_logFC|avg_logFC_|avg_log2FC_", "", fold_change_column)
        if (sigcol != fccol) {
            stop("ERROR: when 'select by rank' is FALSE, make sure to select significance and fold change columns from the same group comparison")
        }
    }

    ## --------- ##
    ## Functions ##
    ## --------- ##

    return_org_genes <- function(l2pout) {
        l2pgenes <- as.list(l2pout$genesinpathway)
        l2pgenes <- lapply(l2pgenes, function(x) unlist(strsplit(x, " ")))
        l2pgenesnew <- lapply(l2pgenes, function(a) l2psupp::o2o(a, "human", species))
        l2pout$orig_genes <- l2pgenesnew
        l2pout$orig_genes <- sapply(l2pout$orig_genes, paste, collapse = " ")
        l2pout <- l2pout %>% arrange(pval)
        return(l2pout)
    }

    return_orig_genes <- function(l2pout, updated_gene_map) {
        l2pgenes <- as.list(l2pout$genesinpathway)
        l2pgenes <- lapply(l2pgenes, function(x) {
            genes <- unlist(strsplit(x, " "))
            genes[!is.na(genes) & genes != ""]
        })

        valid_idx <- !is.na(updated_gene_map) & updated_gene_map != ""
        reverse_map <- split(names(updated_gene_map)[valid_idx], updated_gene_map[valid_idx])

        l2pgenesorig <- lapply(l2pgenes, function(pathway_genes) {
            if (length(pathway_genes) == 0) {
                return(character())
            }
            vapply(pathway_genes, function(gene_symbol) {
                originals <- reverse_map[[gene_symbol]]
                if (is.null(originals) || length(originals) == 0) {
                    return(gene_symbol)
                }
                paste(unique(na.omit(originals)), collapse = "/")
            }, character(1), USE.NAMES = FALSE)
        })

        l2pout$orig_genes <- l2pgenesorig
        l2pout$orig_genes <- vapply(l2pout$orig_genes, function(genes) {
            if (length(genes) == 0) {
                return(NA_character_)
            }
            paste(genes, collapse = " ")
        }, character(1))
        l2pout <- l2pout %>% arrange(pval)
        return(l2pout)
    }

    plotbar <- function(goResults, color_for_bar, use_fdr_pvals, plotitle) {
        colpal <- list(
            "Blue" = "Blues",
            "Green" = "Greens",
            "Grey" = "Greys",
            "Red" = "Reds",
            "Purple" = "Purples",
            "Orange" = "Oranges",
            "GreentoBlue" = "GnBu",
            "OrangetoRed" = "OrRd",
            "YellowOrangeRed" = "YlOrRd"
        )
        pal <- colpal[[color_for_bar]]
        if (use_fdr_pvals == TRUE) {
            df1 <- goResults %>%
                mutate(fdr = -log(fdr)) %>%
                arrange(desc(fdr))
            df1 <- df1 %>% mutate(pathwayname2 = stringr::str_to_upper(.data$pathwayname2))
            gplot <- ggplot(df1, aes(x = reorder(pathwayname2, fdr), y = fdr)) +
                geom_bar(aes(fill = fdr), stat = "identity") +
                scale_fill_distiller(
                    name = expression(paste("-lo", g[10], "(FDR adj ", italic("p"), " value)")),
                    palette = pal, direction = 1
                ) +
                theme_classic() +
                ggtitle(plotitle) +
                labs(
                    y = expression(paste("-lo", g[10], "(FDR adjusted ", italic("p"), " value)")),
                    x = "Pathways"
                ) +
                theme(
                    plot.title = element_text(hjust = 0.5, vjust = 10, size = 20, face = "bold"),
                    plot.margin = margin(t = 50, r = 10, b = 10, l = 10, unit = "pt"),
                    axis.title.y = element_text(size = 20, margin = margin(r = 80)),
                    axis.title.x = element_text(size = 20, margin = margin(t = 20)),
                    axis.text.y = element_text(colour = "black"),
                    axis.text.x = element_text(colour = "black", size = pathway_axis_label_font_size),
                    legend.key.size = unit(1, "cm"),
                    legend.title = element_text(size = 15, margin = margin(b = 15, l = 20)),
                    legend.text = element_text(size = 15)
                ) +
                coord_flip()
        } else {
            df1 <- goResults %>%
                mutate(pval = -log(pval)) %>%
                arrange(desc(pval))
            df1 <- df1 %>% mutate(pathwayname2 = stringr::str_to_upper(.data$pathwayname2))
            gplot <- ggplot(df1, aes(x = reorder(pathwayname2, pval), y = pval)) +
                geom_bar(aes(fill = pval), stat = "identity") +
                scale_fill_distiller(
                    name = expression(paste("-lo", g[10], italic("(p"), "-value)")),
                    palette = pal, direction = 1, limits = c(min(df1$pval) - 1, max(df1$pval))
                ) +
                theme_classic() +
                ggtitle(plotitle) +
                labs(
                    y = expression(paste("-lo", g[10], italic("(p"), "-value)")),
                    x = "Pathways"
                ) +
                theme(
                    plot.title = element_text(hjust = 0.5, vjust = 10, size = 20, face = "bold"),
                    plot.margin = margin(t = 50, r = 10, b = 10, l = 10, unit = "pt"),
                    axis.title.y = element_text(size = 20, margin = margin(r = 80)),
                    axis.title.x = element_text(size = 20, margin = margin(t = 20)),
                    axis.text.y = element_text(colour = "black"),
                    axis.text.x = element_text(colour = "black", size = pathway_axis_label_font_size),
                    legend.key.size = unit(1, "cm"),
                    legend.title = element_text(size = 15, margin = margin(b = 15, l = 20)),
                    legend.text = element_text(size = 15)
                ) +
                coord_flip()
        }
        print(gplot)

        direction <- gsub(" pathways", "", plotitle)
        analysis_prefix_value <- get0("analysis_prefix", ifnotfound = "", inherits = TRUE)
        prefix <- ifelse(analysis_prefix_value != "", paste0(analysis_prefix_value, "_"), "")
        filename <- paste0("L2P_BarPlot_", prefix, gsub(" ", "_", direction), ".png")
        ggplot2::ggsave(filename, plot = gplot, width = 12, height = 10, dpi = 300)
        cat("Bar plot saved as:", filename, "\n")
        return(gplot)
    }

    plotbubble <- function(goResults, plot_bubble_color, plot_bubble_size, sort_bubble_plot_by, plotitle) {
        leglab <- plot_bubble_color
        leglab2 <- plot_bubble_size
        x_label <- sort_bubble_plot_by

        plot_bubble_list <- list(
            "Fisher's Exact pval" = "pval",
            "fdr corrected pval" = "fdr",
            "number of hits" = "number_hits",
            "percent gene hits per pathway" = "percent_gene_hits_per_pathway",
            "enrichment score" = "enrichment_score"
        )
        plot_bubble_size <- plot_bubble_list[[plot_bubble_size]]
        plot_bubble_color <- plot_bubble_list[[plot_bubble_color]]
        sort_bubble_plot_by <- plot_bubble_list[[sort_bubble_plot_by]]

        goResults <- goResults %>% dplyr::mutate(pathwayname2 = stringr::str_to_upper(.data$pathwayname2))

        if (plot_bubble_color %in% c("pval", "fdr")) {
            goResults$color <- -log10(goResults[[plot_bubble_color]])
            leglab <- paste0("-log10(", plot_bubble_color, ")")
        } else {
            goResults$color <- goResults[[plot_bubble_color]]
        }

        if (plot_bubble_size %in% c("pval", "fdr")) {
            goResults$size <- -log10(goResults[[plot_bubble_size]])
            leglab2 <- paste0("-log10(", plot_bubble_size, ")")
        } else {
            goResults$size <- goResults[[plot_bubble_size]]
        }

        if (sort_bubble_plot_by %in% c("pval", "fdr")) {
            goResults$sort <- -log10(goResults[[sort_bubble_plot_by]])
            x_label <- paste0("-log10(", sort_bubble_plot_by, ")")
        } else {
            goResults$sort <- goResults[[sort_bubble_plot_by]]
        }

        goResults$color <- as.numeric(goResults$color)
        minp <- floor(min(goResults$color))
        maxp <- ceiling(max(goResults$color))
        sizemax <- ceiling(max(goResults$size) / 10) * 10

        goResults <- goResults %>% dplyr::mutate(percorder = order(goResults$sort))
        goResults$pathwayname2 <- factor(goResults$pathwayname2, levels = goResults$pathwayname2[goResults$percorder])
        xrange <- max(goResults$sort) - min(goResults$sort)
        xmin <- min(goResults$sort) - 0.1 * xrange
        xmax <- max(goResults$sort) + 0.1 * xrange

        bubblecols <- list(
            "blues" = c("#56B1F7", "#132B43"),
            "reds" = c("#fddbc7", "#b2182b"),
            "blue to red" = c("dark blue", "red")
        )

        gplot <- goResults %>%
            ggplot(aes(x = sort, y = pathwayname2, col = color, size = size)) +
            geom_point() +
            theme_classic() +
            ggtitle(plotitle) +
            labs(col = leglab, size = leglab2, y = "Pathway", x = x_label) +
            theme(
                plot.title = element_text(hjust = 0.5, vjust = 10, size = 20, face = "bold"),
                plot.margin = margin(t = 50, r = 10, b = 10, l = 10, unit = "pt"),
                text = element_text(size = pathway_axis_label_font_size),
                legend.position = "right",
                legend.key.height = unit(1, "cm"),
                axis.title.y = element_text(size = 20, margin = margin(r = 80)),
                axis.title.x = element_text(size = 20, margin = margin(t = 20)),
                axis.text.y = element_text(colour = "black", size = 8),
                axis.text.x = element_text(colour = "black", size = 15),
                legend.key.size = unit(1, "cm"),
                legend.title = element_text(size = 15, margin = margin(b = 15, l = 20)),
                legend.text = element_text(size = 15)
            ) +
            scale_y_discrete(labels = function(x) stringr::str_wrap(x, width = 30)) +
            xlim(xmin, xmax) +
            scale_colour_gradient(low = bubblecols[[bubble_colors]][1], high = bubblecols[[bubble_colors]][2]) +
            expand_limits(colour = seq(minp, maxp, by = 1), size = seq(0, sizemax, by = 10)) +
            guides(colour = guide_colourbar(order = 1), size = guide_legend(order = 2))
        print(gplot)
        return(gplot)
    }

    draw_error_message <- function(message, color, width = 120) {
        segments <- str_split(message, "\n")[[1]]
        wrapped_segments <- lapply(segments, str_wrap, width = width)
        wrapped_message <- paste(unlist(wrapped_segments), collapse = "\n")

        grid.newpage()
        grid.rect(gp = gpar(fill = color, col = NA))
        grid.text(wrapped_message,
            x = 0.5, y = 0.5,
            gp = gpar(fontface = "italic", cex = 3, col = "black"),
            just = "center"
        )
    }

    ## --------------- ##
    ## Main Code Block ##
    ## --------------- ##

    plot_outputs <- list()
    dir_labels <- c("upregulated", "downregulated")
    dir_keys <- c("up", "down")

    rank_selection_limit <- 0.15
    initial_selection_mode <- if (select_by_rank) "rank" else "threshold"
    final_selection_mode <- initial_selection_mode
    selection_switch_triggered <- FALSE
    rank_mode_last_pvals <- c(up = NA_real_, down = NA_real_)
    rank_mode_numselect <- NA_integer_

    generate_rank_lists <- function() {
        genesmat <- deg_table %>%
            dplyr::select(.data[[gene_name_column]], .data[[column_used_to_rank_genes]]) %>%
            dplyr::arrange(desc(.data[[column_used_to_rank_genes]])) %>%
            dplyr::filter(!is.na(.data[[column_used_to_rank_genes]]))

        if (nrow(genesmat) == 0) {
            return(list(
                genes = list(character(), character()),
                lastgene = list(character(), character()),
                numselect = 0L,
                gene_universe = character(),
                significance_column = NA_character_,
                fold_change_column = NA_character_,
                last_pvals = c(up = NA_real_, down = NA_real_)
            ))
        }

        numselect_local <- if (select_top_percentage_of_genes) {
            ceiling(0.1 * nrow(genesmat))
        } else {
            min(select_top_genes, nrow(genesmat))
        }
        up_genes <- head(genesmat[[gene_name_column]], numselect_local)
        down_genes <- rev(tail(genesmat[[gene_name_column]], numselect_local))
        lastgene_up <- if (length(up_genes) > 0) tail(up_genes, 1) else character()
        lastgene_down <- if (length(down_genes) > 0) tail(down_genes, 1) else character()

        grp <- gsub("_tstat", "", column_used_to_rank_genes)
        sig_col <- paste0(grp, "_pval")
        fc_col <- paste0(grp, "_FC")

        last_pval_up <- if (length(lastgene_up) > 0) {
            vals <- deg_table %>%
                dplyr::filter(.data[[gene_name_column]] == lastgene_up) %>%
                dplyr::pull(sig_col)
            if (length(vals) > 0) vals[1] else NA_real_
        } else {
            NA_real_
        }
        last_pval_down <- if (length(lastgene_down) > 0) {
            vals <- deg_table %>%
                dplyr::filter(.data[[gene_name_column]] == lastgene_down) %>%
                dplyr::pull(sig_col)
            if (length(vals) > 0) vals[1] else NA_real_
        } else {
            NA_real_
        }

        list(
            genes = list(up_genes, down_genes),
            lastgene = list(lastgene_up, lastgene_down),
            numselect = numselect_local,
            gene_universe = as.vector(unique(genesmat[[gene_name_column]])),
            significance_column = sig_col,
            fold_change_column = fc_col,
            last_pvals = c(up = as.numeric(last_pval_up), down = as.numeric(last_pval_down))
        )
    }

    generate_threshold_lists <- function(sig_col, fc_col) {
        if (is.null(sig_col) || is.na(sig_col) || sig_col == "") {
            stop("significance_column must be provided when select_by_rank is FALSE")
        }
        if (is.null(fc_col) || is.na(fc_col) || fc_col == "") {
            stop("fold_change_column must be provided when select_by_rank is FALSE")
        }

        using_log_fc <- grepl("logFC|log2FC", fc_col, ignore.case = FALSE)
        up_fc_cutoff <- if (using_log_fc) log2(fold_change_threshold) else fold_change_threshold
        down_fc_cutoff <- if (using_log_fc) -1 * log2(fold_change_threshold) else -1 * fold_change_threshold

        up_genes <- deg_table %>%
            dplyr::arrange(.data[[sig_col]]) %>%
            dplyr::filter(.data[[sig_col]] <= significance_threshold & .data[[fc_col]] >= up_fc_cutoff) %>%
            dplyr::pull(gene_name_column)
        down_genes <- deg_table %>%
            dplyr::arrange(.data[[sig_col]]) %>%
            dplyr::filter(.data[[sig_col]] <= significance_threshold & .data[[fc_col]] <= down_fc_cutoff) %>%
            dplyr::pull(gene_name_column)

        lastgene_up <- if (length(up_genes) > 0) tail(up_genes, 1) else character()
        lastgene_down <- if (length(down_genes) > 0) tail(down_genes, 1) else character()

        last_pval_up <- if (length(lastgene_up) > 0) {
            vals <- deg_table %>%
                dplyr::filter(.data[[gene_name_column]] == lastgene_up) %>%
                dplyr::pull(sig_col)
            if (length(vals) > 0) vals[1] else NA_real_
        } else {
            NA_real_
        }
        last_pval_down <- if (length(lastgene_down) > 0) {
            vals <- deg_table %>%
                dplyr::filter(.data[[gene_name_column]] == lastgene_down) %>%
                dplyr::pull(sig_col)
            if (length(vals) > 0) vals[1] else NA_real_
        } else {
            NA_real_
        }

        list(
            genes = list(up_genes, down_genes),
            lastgene = list(lastgene_up, lastgene_down),
            numselect = NA_integer_,
            gene_universe = as.vector(unique(deg_table[[gene_name_column]])),
            significance_column = sig_col,
            fold_change_column = fc_col,
            last_pvals = c(up = as.numeric(last_pval_up), down = as.numeric(last_pval_down))
        )
    }

    selection_details <- NULL

    if (select_by_rank) {
        rank_details <- generate_rank_lists()
        selection_details <- rank_details
        rank_mode_last_pvals <- rank_details$last_pvals
        rank_mode_numselect <- rank_details$numselect

        if (any(rank_details$last_pvals > rank_selection_limit, na.rm = TRUE)) {
            selection_switch_triggered <- TRUE
            select_by_rank <- FALSE
            final_selection_mode <- "threshold"
            warning(sprintf(
                "Least-significant ranked gene p-values (up: %.3f, down: %.3f) exceeded %.2f; switching to threshold-based gene selection.",
                rank_details$last_pvals["up"], rank_details$last_pvals["down"], rank_selection_limit
            ), call. = FALSE)
            if (is.null(significance_column) || is.na(significance_column) || significance_column == "") {
                significance_column <- rank_details$significance_column
            }
            if (is.null(fold_change_column) || is.na(fold_change_column) || fold_change_column == "") {
                fold_change_column <- rank_details$fold_change_column
            }
        }
    }

    if (!select_by_rank) {
        selection_details <- generate_threshold_lists(significance_column, fold_change_column)
        if (initial_selection_mode == "threshold") {
            final_selection_mode <- "threshold"
        }
    } else {
        final_selection_mode <- "rank"
    }

    genes_to_include <- selection_details$genes
    lastgene <- selection_details$lastgene
    gene_universe_vec <- unique(selection_details$gene_universe[!is.na(selection_details$gene_universe)])

    plotitle <- list("Upregulated Pathways", "Downregulated Pathways")
    x <- list()
    final_last_gene_pvals_from_loop <- c(up = NA_real_, down = NA_real_)

    if (final_selection_mode == "threshold") {
        for (i in seq_along(genes_to_include)) {
            n <- length(genes_to_include[[i]])
            if (i == 1) {
                cat(sprintf("Number of DEG genes using set cut-offs: %s \n", n))
            } else {
                cat(sprintf("Number of DEG genes: %s \n", n))
            }
            if (n < minimum_number_of_DEG_genes) {
                message <- sprintf(
                    "DEG gene count, %d is not enough to find enriched %s. Try to loosen criteria to reach %d or reset minimum number of DEG genes. Ideally, do not go under 50 genes.",
                    n, plotitle[[i]], minimum_number_of_DEG_genes
                )
                draw_error_message(message, color = "lightcoral")
            }
        }
    }

    cat("\n\nOnly pathways that are over-represented are tested by One-Sided Fisher's Exact Test.\nPathways that show under-representation are excluded and not returned")

    for (i in seq_along(genes_to_include)) {
        plot_outputs[[dir_labels[i]]] <- list(bar = NULL, bubble = NULL)
        cat("\n\n")
        cat(sprintf("Analysis of %s :", plotitle[[i]]))
        cat("\n\n")
        genes_to_include[[i]] <- as.vector(unique(unlist(genes_to_include[[i]])))
        gene_universe <- gene_universe_vec

        if (species == "Human") {
            new_gene_names <- sapply(genes_to_include[[i]], function(x) l2psupp::updategenes(x, trust = 1))
            updated_genes_idx <- sapply(seq_along(new_gene_names), function(idx) names(new_gene_names)[idx] != new_gene_names[[idx]])
            updated_genes <- new_gene_names[updated_genes_idx]
            updated_genes_num <- sum(updated_genes_idx)

            cat(paste("\nGene names have been updated to latest names. Number of updated genes is:", updated_genes_num))

            cat("\nOriginal:Updated\n")
            sapply(seq_along(updated_genes), function(idx) print(paste0(names(updated_genes)[idx], ":", updated_genes[idx])))

            genes_to_include[[i]] <- as.character(new_gene_names)
            gene_universe <- l2psupp::updategenes(gene_universe, trust = 1)
            lastgene[[i]] <- names(tail(new_gene_names, 1))
        } else {
            orth_genes <- sapply(genes_to_include[[i]], function(x) l2psupp::o2o(x, species, "human")[1])
            no_orth <- names(orth_genes[unlist(lapply(orth_genes, function(x) is.na(x)))])
            orth <- orth_genes[unlist(lapply(orth_genes, function(x) !is.na(x)))]

            num_no_orth <- length(no_orth)
            perc_num_no_orth <- formatC((length(no_orth) / length(genes_to_include[[i]])) * 100, digits = 2, format = "f")
            num_orth <- length(orth)
            perc_num_orth <- formatC((length(orth) / length(genes_to_include[[i]])) * 100, digits = 2, format = "f")

            cat(paste("\n\nNumber of genes in the genelist without a homologue:", num_no_orth, ", Percentage:", perc_num_no_orth, "%\n"))
            cat(no_orth)

            cat(paste("\n\nNumber of genes in the genelist with a homologue:", num_orth, ",Percentage:", perc_num_orth, "%\n"))
            cat("\nGene:Homolog\n")
            cat(sapply(seq_along(orth), function(idx) paste0(names(orth)[idx], ":", orth[idx])))

            lastgene[[i]] <- names(tail(orth, 1))
            genes_to_include[[i]] <- as.character(unlist(orth))

            orth_gene_universe <- sapply(gene_universe, function(x) l2psupp::o2o(x, species, "human")[1])
            no_orth_gu <- names(orth_gene_universe[unlist(lapply(orth_gene_universe, function(x) is.na(x)))])
            orth_gu <- orth_gene_universe[unlist(lapply(orth_gene_universe, function(x) !is.na(x)))]

            gene_universe <- as.character(unlist(orth_gu))

            num_no_orth <- length(no_orth_gu)
            num_orth <- length(orth_gu)
            cat(paste("\n\nNumber of genes in the gene universe without a homologue:", num_no_orth, "\n"))
            cat(paste("Number of genes in the gene universe with a homologue:", num_orth, "\n"))
        }

        sizegenelist <- length(genes_to_include[[i]])
        sizeuniv <- length(gene_universe)

        cat("\n\nNumber of genes selected for pathway analysis: ", sizegenelist)
        cat("\nSize of gene universe: ", sizeuniv)
        pctuniv <- (sizegenelist / sizeuniv) * 100
        pctuniv <- formatC(pctuniv, digits = 2, format = "f")
        cat(paste0("\nFinal genelist as percent of gene universe (ideally < 20 %) : ", pctuniv, "%\n"))

        if (select_by_rank == FALSE) {
            current_fc_col <- fold_change_column
            current_sig_col <- significance_column
            lastgenedat <- deg_table %>%
                dplyr::filter(.data[[gene_name_column]] == lastgene[[i]]) %>%
                dplyr::select(dplyr::all_of(c(gene_name_column, current_fc_col, current_sig_col)))
        } else {
            grp <- gsub("_tstat", "", column_used_to_rank_genes)
            current_fc_col <- paste0(grp, "_FC")
            current_sig_col <- paste0(grp, "_pval")
            lastgenedat <- deg_table %>%
                dplyr::filter(.data[[gene_name_column]] == lastgene[[i]]) %>%
                dplyr::select(dplyr::all_of(c(gene_name_column, column_used_to_rank_genes, current_fc_col, current_sig_col)))
        }

        cat("\n\nCheck p-value for least significant gene in genelist (ideally p <= 0.15) :\n\n")
        print(lastgenedat)
        if (nrow(lastgenedat) > 0 && current_sig_col %in% colnames(lastgenedat)) {
            final_last_gene_pvals_from_loop[dir_keys[i]] <- lastgenedat[[current_sig_col]][1]
        }

        if (use_built_in_gene_universe == TRUE) {
            x[[i]] <- l2p::l2p(genes_to_include[[i]], categories = collections_to_include)
            cat("\n\nUsing built-in gene universe.\n")
            cat(paste0("Total number of pathways tested: ", nrow(x[[i]])))
        } else {
            x[[i]] <- l2p::l2p(genes_to_include[[i]], categories = collections_to_include, universe = gene_universe)
            cat("\n\nUsing all genes included in the differential expression analysis as gene universe.\n\n")
            cat(paste0("Total number of pathways tested: ", nrow(x[[i]])))
        }

        if (!"genesinpathway" %in% names(x[[i]]) && "allgenesinpw" %in% names(x[[i]])) {
            x[[i]] <- dplyr::rename(x[[i]], genesinpathway = allgenesinpw)
        }

        x[[i]] <- x[[i]] %>%
            select(pathway_name, category, number_hits, percent_gene_hits_per_pathway, enrichment_score, pval, fdr, genesinpathway) %>%
            mutate(percent_gene_hits_per_pathway = percent_gene_hits_per_pathway) %>%
            dplyr::filter(number_hits >= minimum_pathway_hit_count) %>%
            dplyr::filter(number_hits <= maximum_pathway_hit_count) %>%
            dplyr::filter(pval < p_value_threshold_for_output) %>%
            arrange(pval)

        if (nrow(x[[i]]) > 0) {
            if (species != "Human") {
                x[[i]] <- as.data.frame(return_org_genes(x[[i]]))
            } else {
                x[[i]] <- as.data.frame(return_orig_genes(x[[i]], new_gene_names))
            }

            x[[i]]$enrichment_score <- as.numeric(formatC(x[[i]]$enrichment_score, digits = 3, format = "f"))
            x[[i]]$percent_gene_hits_per_pathway <- as.numeric(formatC(x[[i]]$percent_gene_hits_per_pathway, digits = 3, format = "f"))
            x[[i]]$direction <- plotitle[[i]]
            x[[i]] <- head(x[[i]], 500)
        } else {
            message <- sprintf(
                "No results for %s \n Try loosening the criteria (e.g. pvals up to < 0.15, FC > 1) to get more genes",
                plotitle[[i]]
            )
            draw_error_message(message, color = "lightcoral")
            x[[i]] <- NULL
        }
    }

    final_gene_counts <- stats::setNames(sapply(genes_to_include, length), dir_keys)
    collapse_vector <- function(vec) {
        if (length(vec) == 0) {
            return("")
        }
        paste(vec, collapse = "; ")
    }

    run_parameters <- list(
        selection_mode_initial = initial_selection_mode,
        selection_mode_final = final_selection_mode,
        rank_selection_cutoff_p_value = rank_selection_limit,
        rank_selection_switch_triggered = selection_switch_triggered,
        rank_mode_numselect = rank_mode_numselect,
        rank_mode_least_significant_gene_pval_up = rank_mode_last_pvals["up"],
        rank_mode_least_significant_gene_pval_down = rank_mode_last_pvals["down"],
        final_up_genelist_size = final_gene_counts["up"],
        final_down_genelist_size = final_gene_counts["down"],
        final_up_least_significant_gene_pval = final_last_gene_pvals_from_loop["up"],
        final_down_least_significant_gene_pval = final_last_gene_pvals_from_loop["down"],
        final_gene_universe_size = length(gene_universe_vec),
        significance_threshold = significance_threshold,
        fold_change_threshold = fold_change_threshold,
        select_top_percentage_of_genes = select_top_percentage_of_genes,
        select_top_genes = select_top_genes,
        minimum_number_of_DEG_genes = minimum_number_of_DEG_genes,
        collections_to_include = collapse_vector(collections_to_include),
        pathways_selected_up = if (plot_top_pathways_up) "auto" else collapse_vector(pathways_to_use_up),
        pathways_selected_down = if (plot_top_pathways_down) "auto" else collapse_vector(pathways_to_use_down),
        minimum_pathway_hit_count = minimum_pathway_hit_count,
        maximum_pathway_hit_count = maximum_pathway_hit_count,
        p_value_threshold_for_output = p_value_threshold_for_output,
        use_fdr_pvals = use_fdr_pvals,
        threshold_significance_column = significance_column,
        threshold_fold_change_column = fold_change_column
    )

    if (!all(sapply(x, is.null))) {
        for (i in seq_along(x)) {
            if (is.null(x[[i]])) {
                next
            }
            goResults <- x[[i]] %>% dplyr::mutate(pathwayname2 = stringr::str_replace_all(pathway_name, "_", " "))
            goResults$pathwayname2 <- str_to_upper(goResults$pathwayname2)
            goResults$pathwayname2 <- trimws(goResults$pathwayname2)
            goResults <- goResults %>% dplyr::mutate(pathwayname2 = stringr::str_wrap(pathwayname2, pathway_axis_label_max_length))
            goResults <- distinct(goResults, pathwayname2, .keep_all = TRUE)

            if (i == 1) {
                if (plot_top_pathways_up == TRUE) {
                    goResults <- goResults %>% top_n(number_of_pathways_to_plot, wt = -log(pval))
                } else {
                    goResults <- goResults %>% dplyr::filter(.data[["pathway_name"]] %in% pathways_to_use_up)
                    if (nrow(goResults) < length(pathways_to_use_up)) {
                        cat("\nSome selected pathways are not showing in plot, check for spelling errors:\n\n")
                        cat(pathways_to_use_up[!pathways_to_use_up %in% goResults[["pathway_name"]]])
                    }
                }
            } else {
                if (plot_top_pathways_down == TRUE) {
                    goResults <- goResults %>% top_n(number_of_pathways_to_plot, wt = -log(pval))
                } else {
                    goResults <- goResults %>% dplyr::filter(.data[["pathway_name"]] %in% pathways_to_use_down)
                    if (nrow(goResults) < length(pathways_to_use_down)) {
                        cat("\nSome selected pathways are not showing in plot, check for spelling errors:\n\n")
                        cat(pathways_to_use_down[!pathways_to_use_down %in% goResults[["pathway_name"]]])
                    }
                }
            }
            if (nrow(goResults) < number_of_pathways_to_plot) {
                numpath <- nrow(goResults)
                message <- sprintf(
                    "Only %d significant %s. Try to loosen criteria to get more genes and enriched pathways",
                    numpath, plotitle[[i]]
                )
                draw_error_message(message, color = "lightcoral")
            }
            bar_plot <- plotbar(goResults, color_for_bar, use_fdr_pvals, plotitle[[i]])
            bubble_plot <- NULL
            if (plot_bubble) {
                bubble_plot <- plotbubble(goResults, plot_bubble_color, plot_bubble_size, sort_bubble_plot_by, plotitle[[i]])
            }
            plot_outputs[[dir_labels[i]]] <- list(bar = bar_plot, bubble = bubble_plot)
        }

        combined_paths <- do.call(rbind, x[!sapply(x, is.null)])
        combined_paths <- combined_paths %>% arrange(pval)
        combined_paths$pval <- sprintf("%.2e", combined_paths$pval)
        combined_paths$fdr <- sprintf("%.2e", combined_paths$fdr)
        combined_paths <- combined_paths %>% select(pathway_name, category, direction, number_hits, percent_gene_hits_per_pathway, enrichment_score, pval, fdr, genesinpathway, orig_genes)
        run_parameters$total_pathways_returned <- nrow(combined_paths)
        return(list(pathways = combined_paths, plots = plot_outputs, run_parameters = run_parameters))
    } else {
        message <- "No pathway results. Try to loosen criteria to get more up and downregulated genes"
        draw_error_message(message, color = "lightcoral")
        run_parameters$total_pathways_returned <- 0
        return(list(pathways = NULL, plots = plot_outputs, run_parameters = run_parameters))
    }
}

