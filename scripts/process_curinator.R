library(ellmer)
library(dplyr)
library(ragnar)
library(purrr)
library(reticulate)
library(jsonlite)

source("scripts/parse_curinator.R")

read_md <- function(filepath) {
  paste(readLines(filepath), collapse = "\n")
}

try_read_as_markdown <- function(url){
  tryCatch(
    ragnar::read_as_markdown(url),
    error = function(e) {
      warning("Failed to read URL: ", url, " - ", e$message)
      NA  # Return NA when there's an error
    }
  )
}

md_links <- parse_curinator_md("curatinator_latest.md") |>
  filter(`type` == "RSS POSTS") |>
  mutate(content = map_chr(link, try_read_as_markdown)) |>
  # limit character length of content to 1000 characters to respect model token limits
  mutate(content = substr(content, 1, 1000)) |>
  # limiting it to 2 RSS posts for testing purposes
  head(2)

system_prompt <- read_md("scripts/curinator_system_prompt.md")

chat <- ellmer::chat_openai(
  system_prompt = system_prompt,
  model = "gpt-5"
)

set.seed(as.numeric(Sys.time()))
xml_tag <- paste0("info_", sample(500:9999, 1))

prompts <- interpolate(
"<{{xml_tag}}>
  Title: {{md_links$title}}
  Link: {{md_links$link}}
  Content: {{md_links$content}}
  </{{xml_tag}}>"
)

result <- md_links |>
  mutate(
    is_r_related = parallel_chat_text(
      chat,
      prompt = prompts
    )
  ) |>
  mutate(is_r_related = map(is_r_related, ~ fromJSON(.x)))
