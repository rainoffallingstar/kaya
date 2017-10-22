


parse_sgf <- function(sgf_lines){

  sgf_lines <- paste(sgf_lines, collapse="\n")
  sgf_lines <- gsub("\n", "", sgf_lines)

  # if multiple games, and nothing in-between them
  sgf_lines <- gsub("\\)\\(;", "\\)~tb~\\(;", sgf_lines)
  sgf_lines <- strsplit(sgf_lines, "~tb~")[[1]]

  n_games <- length(sgf_lines)
  output <- list()

  if( n_games == 1 ){

    game_start <- regexpr("\\(;", sgf_lines)[1]
    game_stop <- max(gregexpr(")", sgf_lines)[[1]])

    sgf_lines <- substr(sgf_lines, game_start+2, game_stop-1)

#    sgf_lines <- strsplit(sgf_lines, ";")[[1]]
    sgf_lines <- gsub("\\];", "\\]~tb~;", sgf_lines)
    sgf_lines <- strsplit(sgf_lines, "~tb~;")[[1]]

    metadata <- sgf_lines[1]

    metadata <- gsub("\\]","\\]~tb~", metadata)
    metadata <- gsub("\\]~tb~\\[","\\]\\[", metadata)
    metadata <- strsplit(metadata, "~tb~")[[1]]

    moves <- data.frame(move=character(), 
      color=character(), coord_sgf=character())
    hash_id <- NA
    n_moves <- 0

    if( length(sgf_lines) > 1 ){

      move_stuff <- sgf_lines[2:length(sgf_lines)]

      comment <- rep("", length(move_stuff))
      comment_moves <- grep("C\\[", move_stuff)
      if(length(comment_moves)>0){
        move_stuff <- stringi::stri_trans_general(move_stuff, "latin-ascii") # convert non-ASCII to closest ascii
        move_stuff <- gsub("[\x01-\x1F]", "", move_stuff) # takes care of non-printing ASCII
        move_stuff <- iconv(move_stuff, "latin1", "ASCII", sub="") # strip out non-ASCII entirely
        # slow!
        comment <- substr(move_stuff, 6, nchar(move_stuff))
        comment[comment_moves] <- sapply(comment[comment_moves], function(z) as.character(extract_sgf_tag(z)))
        comment <- as.character(comment)
      }

      moves <- substr(move_stuff, 1, 5) # strip out comments, if any
      hash_id <- substr(digest::sha1(moves), 1, 19)
      move <- 1:length(moves)
      color <- substr(moves, 1, 1)
      coord_sgf <- sapply(moves, function(z) as.character(extract_sgf_tag(z)))
      coord_sgf <- as.character(coord_sgf)
  
      moves <- data.frame(move, color, coord_sgf, comment)

      n_moves <- nrow(moves)

    }

    meta <- list()
    for(i in 1:length(metadata)){
      # if is tag
      tag <- extract_sgf_tag(metadata[i])
      meta <- c(meta, tag)
    }
    
    output <- meta
    output$hash_id <- hash_id
    output$n_moves <- n_moves
    output$moves <- moves

  }

  if( n_games > 1 ){

    output <- lapply_pb(sgf_lines, parse_sgf)

  }

  return(output)

}

