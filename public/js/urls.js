"use strict";

var BASE_URL = "https://thawing-river-5767.herokuapp.com";
function game_url(game_id) {
  return "" + BASE_URL + "/" + game_id;
}
function create_url() {
  return "" + BASE_URL + "/create";
}
function guess_url(game_id) {
  return "" + BASE_URL + "/" + game_id + "/guess";
}
