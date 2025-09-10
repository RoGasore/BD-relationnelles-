#!/bin/bash

PSQL="psql -X --username=freecodecamp --dbname=number_guess -t -c"

ADD_NUMBER_TO_GUESS() {
  NUMBER_TO_GUESS=$(( ( RANDOM % 1000 )  + 1 ))
}

INITIAL_ROUND() {
  echo "Guess the secret number between 1 and 1000:"
  read USER_NUMBER
  ATTEMPTS=$((ATTEMPTS+1))
  CHECK_NUMBER $USER_NUMBER
}

CHECK_NUMBER() {
  if [[ ! $1 =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    PLAY_EXTRA_ROUND
  else
    if [[ $1 = $NUMBER_TO_GUESS ]]
    then
      echo -e "\nYou guessed it in $ATTEMPTS tries. The secret number was $NUMBER_TO_GUESS. Nice job!"
    else
      if [[ $1 -gt $NUMBER_TO_GUESS ]]
      then
        echo "It's lower than that, guess again:"
        PLAY_EXTRA_ROUND
      else
        echo "It's higher than that, guess again:"
        PLAY_EXTRA_ROUND
      fi
    fi
  fi
}

PLAY_EXTRA_ROUND() {
  read USER_NUMBER
  ATTEMPTS=$((ATTEMPTS+1))
  CHECK_NUMBER $USER_NUMBER
}

PLAY_GAME() {
  ADD_NUMBER_TO_GUESS
  ATTEMPTS=0
  INITIAL_ROUND
  SAVE_GAME_INFO=$($PSQL "INSERT INTO games(attempts) VALUES($ATTEMPTS);")
  GAME_ID=$($PSQL "SELECT game_id FROM games ORDER BY game_id DESC LIMIT 1;")
  SAVE_USER_GAME_INFO=$($PSQL "INSERT INTO users_games(user_id, game_id) VALUES($USER_ID, $GAME_ID);")
}

echo "Enter your username:"
read USER_NAME

# Get user_id from database
USER_ID=$($PSQL "SELECT user_id FROM users WHERE name = '$USER_NAME';")

if [[ -z $USER_ID ]]
then
  # Create new user
  USER_INSERT=$($PSQL "INSERT INTO users(name) VALUES('$USER_NAME');")
  # Greet new user
  echo "Welcome, $USER_NAME! It looks like this is your first time here."
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE name = '$USER_NAME';")

  # Play game
  PLAY_GAME
else
  # Get number of played games
  GAMES_PLAYED=$($PSQL "SELECT COUNT(user_id) FROM users AS u
                        INNER JOIN users_games USING(user_id)
                        INNER JOIN games USING(game_id)
                        WHERE u.user_id = $USER_ID;")
  BEST_SCORE=$($PSQL "SELECT MIN(attempts) FROM users AS u
                        INNER JOIN users_games USING(user_id)
                        INNER JOIN games USING(game_id)
                        WHERE u.user_id = $USER_ID;")
  # Greet existing user
  echo "Welcome back, $USER_NAME! You have played $GAMES_PLAYED games, and your best game took $BEST_SCORE guesses."

  # Play game
  PLAY_GAME
fi