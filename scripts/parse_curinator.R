#' Parse a "curinator latest" Markdown file into a tidy data frame
#'
#' @param path Character path to the Markdown file.
#' @return data.frame with columns: type (section), title, link
#' @examples
#' # md <- parse_curinator_md("curinator_latest.md")
#' # head(md)
parse_curinator_md <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  
  # Patterns
  header_pat <- "^#\\s*.*?\\s*##\\s*$"                 # e.g., "# RSS POSTS: ##"
  link_pat   <- "^\\+\\s*\\[(.*?)\\]\\((.*?)\\)\\s*$"  # e.g., "+ [Title](URL)"
  
  # Identify headers and compute section IDs via forward-fill using cumsum
  is_header <- grepl(header_pat, lines)
  section_id <- cumsum(is_header)  # 0 for pre-first-header content
  
  # Extract clean section names for header rows
  header_names <- ifelse(
    is_header,
    sub("^#\\s*(.*?)\\s*##\\s*$", "\\1", lines),
    NA_character_
  )
  
  # Identify link rows and extract titles/links
  is_link <- grepl(link_pat, lines)
  titles  <- sub(link_pat, "\\1", lines[is_link])
  links   <- sub(link_pat, "\\2", lines[is_link])
  
  # Map each link row's section_id to its header name
  # section_id values for header rows are the "keys"
  header_keys  <- section_id[is_header]
  header_vals  <- header_names[is_header]
  
  # For link rows that occur before any header (section_id == 0), use NA
  link_sids <- section_id[is_link]
  type_raw <- ifelse(
    link_sids == 0,
    NA_character_,
    header_vals[match(link_sids, header_keys)]
  )
  
  # Normalize section names: drop trailing ":" if present
  type <- sub(":\\s*$", "", type_raw)
  
  # Assemble a tidy data frame
  tibble::tibble(
    type = type,
    title = titles,
    link  = links
  )
}