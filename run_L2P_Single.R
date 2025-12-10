args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 14) {
    stop(paste(
        "Usage:",
        "Rscript run_L2P_Single.R",
        "<input_deg> <output_csv>",
        "<bar_up_png> <bar_down_png> <bubble_up_png> <bubble_down_png>",
        "<gene_name_column> <species>",
        "<select_by_rank> <rank_column>",
        "<significance_column> <fold_change_column>",
        "<significance_threshold> <fold_change_threshold>",
        sep = "\n"
    ))
}

input_deg          <- args[1]
output_csv         <- args[2]
bar_up_png         <- args[3]
bar_down_png       <- args[4]
bubble_up_png      <- args[5]
bubble_down_png    <- args[6]
gene_name_column   <- args[7]
species            <- args[8]
select_by_rank     <- as.logical(args[9])
rank_column        <- args[10]
significance_column<- args[11]
fold_change_column <- args[12]
significance_threshold <- as.numeric(args[13])
fold_change_threshold  <- as.numeric(args[14])

message("Running L2P_Single with:")
message("  input_deg: ", input_deg)
message("  output_csv: ", output_csv)
message("  bar_up_png: ", bar_up_png)
message("  bar_down_png: ", bar_down_png)
message("  bubble_up_png: ", bubble_up_png)
message("  bubble_down_png: ", bubble_down_png)
message("  gene_name_column: ", gene_name_column)
message("  species: ", species)
message("  select_by_rank: ", select_by_rank)
message("  rank_column: ", rank_column)
message("  significance_column: ", significance_column)
message("  fold_change_column: ", fold_change_column)
message("  significance_threshold: ", significance_threshold)
message("  fold_change_threshold: ", fold_change_threshold)

suppressPackageStartupMessages({
    library(ggplot2)
    library(grid)
})

source("/opt/l2p_single/L2P_Single.R")

deg <- read.delim(input_deg, sep = "\t", stringsAsFactors = FALSE, check.names = FALSE)

res <- L2P_Single(
    deg_table                         = deg,
    gene_name_column                  = gene_name_column,
    species                           = species,
    collections_to_include            = c("GO", "REACTOME", "KEGG"),
    select_by_rank                    = select_by_rank,
    column_used_to_rank_genes         = rank_column,
    select_top_percentage_of_genes    = TRUE,
    select_top_genes                  = 500,
    significance_column               = significance_column,
    significance_threshold            = significance_threshold,
    fold_change_column                = fold_change_column,
    fold_change_threshold             = fold_change_threshold,
    minimum_number_of_DEG_genes       = 50,
    number_of_pathways_to_plot        = 12,
    plot_top_pathways_up              = TRUE,
    pathways_to_use_up                = character(),
    plot_top_pathways_down            = TRUE,
    pathways_to_use_down              = character(),
    pathway_axis_label_font_size      = 15,
    pathway_axis_label_max_length     = 50,
    sort_bubble_plot_by               = "percent gene hits per pathway",
    plot_bubble_size                  = "number of hits",
    plot_bubble_color                 = "Fisher's Exact pval",
    bubble_colors                     = "blues",
    use_fdr_pvals                     = FALSE,
    color_for_bar                     = "GreentoBlue",
    use_built_in_gene_universe        = FALSE,
    minimum_pathway_hit_count         = 5,
    maximum_pathway_hit_count         = 200,
    p_value_threshold_for_output      = 0.05,
    plot_bubble                       = TRUE
)

# Helper to always create a PNG, even if the plot is NULL
save_plot_or_message <- function(plot_obj, filepath, msg) {
    if (!is.null(plot_obj)) {
        ggplot2::ggsave(filename = filepath, plot = plot_obj, device = "png",
                        width = 10, height = 8, dpi = 150)
    } else {
        grDevices::png(filepath, width = 1200, height = 800, res = 120)
        grid::grid.newpage()
        grid::grid.text(msg,
                        x = 0.5, y = 0.5,
                        gp = grid::gpar(cex = 2))
        grDevices::dev.off()
    }
}

# res$plots is a list with elements "upregulated" and "downregulated"
# each has $bar and $bubble (possibly NULL)
if (!is.null(res$plots[["upregulated"]])) {
    save_plot_or_message(
        res$plots[["upregulated"]][["bar"]],
        bar_up_png,
        "No upregulated pathways / bar plot available"
    )
    save_plot_or_message(
        res$plots[["upregulated"]][["bubble"]],
        bubble_up_png,
        "No upregulated pathways / bubble plot available"
    )
} else {
    save_plot_or_message(NULL, bar_up_png,
                         "No upregulated pathways / bar plot available")
    save_plot_or_message(NULL, bubble_up_png,
                         "No upregulated pathways / bubble plot available")
}

if (!is.null(res$plots[["downregulated"]])) {
    save_plot_or_message(
        res$plots[["downregulated"]][["bar"]],
        bar_down_png,
        "No downregulated pathways / bar plot available"
    )
    save_plot_or_message(
        res$plots[["downregulated"]][["bubble"]],
        bubble_down_png,
        "No downregulated pathways / bubble plot available"
    )
} else {
    save_plot_or_message(NULL, bar_down_png,
                         "No downregulated pathways / bar plot available")
    save_plot_or_message(NULL, bubble_down_png,
                         "No downregulated pathways / bubble plot available")
}

# Write pathways table
if (!is.null(res$pathways)) {
    write.table(res$pathways, file = output_csv, sep = ",", row.names = FALSE, quote = FALSE, col.names = TRUE)
} else {
    message("No pathways returned; writing empty CSV.")
    write.table(data.frame(), file = output_csv, sep = ",", row.names = FALSE, quote = FALSE, col.names = TRUE)
}
