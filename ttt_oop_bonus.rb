module UI
  def enter_to_continue
    space_puts "Press enter to continue..."
    gets
    clear
  end

  def pause
    sleep 1
  end

  def clear
    system 'clear'
  end

  def space_puts(input)
    puts
    puts input
  end

  def joinor(array, delimiter = ', ', conjunction = 'or')
    return array.first if array.size == 1
    array[0..-2].join(delimiter) + delimiter +
      conjunction + ' ' + array[-1].to_s
  end

  COMPUTER_OPPONENTS = <<-MSG
Chose your opponent: (enter a number)
  (1) DJ Roomba (beginner)
  (2) R2D2 (moderate)
  (3) Hal (advanced)
MSG

  GAME_INFO = <<-MSG

*** A Guide to Tic Tac Toe ***

How to win: A round is won if a player is able to select 3 squares in a row,
either horizontally, vertically, or diagonally.

Taking turns: The user chooses who will play first. Afterwards, the order of
turns alternates each round.

Selecting a square: The squares are numbered from 1 - 9. To select a square,
type the square's number using the guide below as reference.

 -----------
| 1 | 2 | 3 |
|---+---+---|
| 4 | 5 | 6 |
|---+---+---|
| 7 | 8 | 9 |
 -----------
MSG
end

class Board
  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] + # rows
                  [[1, 4, 7], [2, 5, 8], [3, 6, 9]] + # cols
                  [[1, 5, 9], [3, 5, 7]] # diagonals

  attr_reader :squares

  def initialize
    @squares = {}
    reset
  end

  def unmarked_keys
    @squares.select { |_, sq| sq.unmarked? }.keys
  end

  def unmarked_corners
    unmarked_keys.select { |key| [1, 3, 7, 9].include?(key) }
  end

  def full?
    unmarked_keys.empty?
  end

  def someone_won?
    !!winning_marker
  end

  def winning_marker
    WINNING_LINES.each do |line|
      marker = @squares[line[0]].marker
      next if marker == ' '
      return marker if line.all? { |num| @squares[num].marker == marker }
    end
    nil
  end

  def reset
    (1..9).each { |key| @squares[key] = Square.new }
  end

  # rubocop:disable Metrics/MethodLength
  def display
    gameboard = <<-MSG
         |     |                            Square Number
      #{@squares[1]}  |  #{@squares[2]}  |  #{@squares[3]}                          -----------
         |     |                            | 1 | 2 | 3 |
    -----+-----+-----                       |---+---+---|
         |     |                            | 4 | 5 | 6 |
      #{@squares[4]}  |  #{@squares[5]}  |  #{@squares[6]}                         |---+---+---|
         |     |                            | 7 | 8 | 9 |
    -----+-----+-----                        -----------
         |     |                                Guide
      #{@squares[7]}  |  #{@squares[8]}  |  #{@squares[9]}
         |     |
    MSG
    puts gameboard
  end
  # rubocop:enable Metrics/MethodLength

  def []=(num, player_marker)
    @squares[num].marker = player_marker
  end
end

class Square
  INITIAL_MARKER = " "

  attr_accessor :marker

  def initialize(marker=INITIAL_MARKER)
    @marker = marker
  end

  def to_s
    @marker
  end

  def unmarked?
    marker == INITIAL_MARKER
  end
end

class Player
  attr_reader :marker, :name

  def initialize(name, marker)
    @marker = marker
    @name = name
  end

  private

  attr_reader :opponent_marker
end

class Human < Player
  include UI

  def initialize(name, marker)
    super(name, marker)
    @opponent_marker = find_opponent_marker
  end

  def moves(board)
    puts "Choose a square (#{joinor(board.unmarked_keys)}) "
    square = nil
    loop do
      square = gets.chomp.to_i
      break if board.unmarked_keys.include?(square)
      puts "Sorry, thats not a valid choice."
    end
    board[square] = marker
  end

  private

  def find_opponent_marker
    marker == 'X' ? 'O' : 'X'
  end
end

class Computer < Player
  def initialize(name, marker, opponent_marker)
    super(name, marker)
    @opponent_marker = opponent_marker
  end

  private

  def choose_unmarked_key(board)
    board[board.unmarked_keys.sample] = marker
  end

  def find_at_risk_squares(board, player_marker) # returns array of keys or nil
    at_risk_squares = []
    Board::WINNING_LINES.each do |line|
      square = find_third_in_a_row(line, board, player_marker)
      at_risk_squares << square if square
    end
    return at_risk_squares unless at_risk_squares.empty?
    nil
  end

  def find_third_in_a_row(line, board, player_marker) # returns a key or nil
    count = board.squares.values_at(*line).count do |square|
      square.marker == player_marker
    end
    return unless count == 2
    board.squares.select do |k, v|
      line.include?(k) && v.unmarked?
    end.keys.first
  end
end

class Hal < Computer # uses AI to attempt to win
  def moves(board)
    square = if find_at_risk_squares(board, marker)
               find_at_risk_squares(board, marker).first
             elsif find_at_risk_squares(board, opponent_marker)
               find_at_risk_squares(board, opponent_marker).first
             else
               no_risk_moves(board)
             end
    board[square] = marker
  end

  private

  def no_risk_moves(board)
    square = if board.squares[5].unmarked?
               5
             elsif board.unmarked_corners != []
               board.unmarked_corners[0]
             else
               board.unmarked_keys.sample
             end
    square
  end
end

class R2D2 < Computer # selects randomly
  def moves(board)
    choose_unmarked_key(board)
  end
end

class DjRoomba < Computer # avoids selecting three in a row whenever possible
  def moves(board)
    squares_to_avoid = find_at_risk_squares(board, marker)
    if !squares_to_avoid
      choose_unmarked_key(board)
    else
      avoid_winning_keys(squares_to_avoid, board)
    end
  end

  def avoid_winning_keys(squares_to_avoid, board)
    losing_keys = board.unmarked_keys.reject do |keys|
      squares_to_avoid.include?(keys)
    end
    if losing_keys.empty?
      choose_unmarked_key(board)
    else
      board[losing_keys.sample] = marker
    end
  end
end

class Scoreboard
  include UI
  attr_accessor :human_wins, :computer_wins, :ties, :grand_winner

  def initialize(grand_winner)
    @human_wins = 0
    @computer_wins = 0
    @ties = 0
    @grand_winner = grand_winner
  end

  def display(human_name, computer_name)
    update_message(human_name, computer_name)
    space_puts [banner, horizontal_rule,
                empty_line, message_line, empty_line,
                horizontal_rule].join("\n")
  end

  protected

  attr_accessor :message

  def update_message(human_name, computer_name)
    self.message =
      "#{human_name}'s wins: #{human_wins}       "\
      "#{computer_name}'s wins:  #{computer_wins}       "\
      "Ties: #{ties}".center(60)
  end

  private

  def banner
    "Scoreboard: First player to #{grand_winner} wins "\
    "is the Grand-winner!"
  end

  def empty_line
    "| #{' ' * (@message.size)} |"
  end

  def horizontal_rule
    "+-#{'-' * (@message.size)}-+"
  end

  def message_line
    "| #{@message} |"
  end
end

class TTTGame
  include UI

  def initialize
    @board = Board.new
    @human = nil
    @computer = nil
    @first_to_move = nil
    @current_marker = nil
    @grand_winner = nil
    @scoreboard = nil
  end

  def play
    clear
    game_setup
    main_game
    display_goodbye_message
  end

  private

  attr_accessor :human, :computer, :scoreboard, :grand_winner,
                :current_marker, :first_to_move

  attr_reader :board

  def main_game
    loop do
      single_round
      display_grand_winner
      break unless play_again?
      display_play_again_message
      new_game
      reset
    end
  end

  def single_round
    loop do
      players_take_turns
      update_scoreboard
      display_result
      scoreboard.display(human.name, computer.name)
      break if grand_winner?
      enter_to_continue
      reset
    end
  end

  def players_take_turns
    loop do
      clear_screen_and_display_board
      current_player_moves
      break if board.someone_won? || board.full?
    end
  end

  def game_setup
    display_welcome_message
    ask_rules
    initialize_players
    set_first_move
    self.current_marker = @first_to_move
    set_grand_winner
    initialize_scoreboard
  end

  def ask_rules
    answer = nil
    loop do
      space_puts "Would you like to see the rules: (Y)es or (N)o?"
      answer = gets.chomp.downcase
      break if %w(yes no y n).include?(answer)
      puts "Sorry, please enter 'yes', 'no', 'y', or 'n'"
    end
    show_rules if %w(yes y).include?(answer)
  end

  def show_rules
    clear
    puts GAME_INFO
    enter_to_continue
  end

  def initialize_scoreboard
    self.scoreboard = Scoreboard.new(grand_winner)
  end

  def initialize_players
    self.human = Human.new(ask_human_name, choose_marker)
    self.computer = initialize_opponent
  end

  def choose_opponent
    clear
    response = ''
    loop do
      space_puts COMPUTER_OPPONENTS
      response = gets.chomp.to_i
      break if [1, 2, 3].include?(response)
      puts "Invalid input: please enter 1, 2, or 3."
    end
    response
  end

  def initialize_opponent
    response = choose_opponent
    case response
    when 1 then DjRoomba.new('DJ Roomba', set_computer_marker, human.marker)
    when 2 then R2D2.new('R2D2', set_computer_marker, human.marker)
    when 3 then Hal.new('Hal', set_computer_marker, human.marker)
    end
  end

  def choose_order
    clear
    response = ''
    loop do
      space_puts "Would you like to take the first move? "\
                 "(Y)es, (N)o, or (R)andom?"
      response = gets.chomp.downcase
      break if %w(yes no random y n r).include?(response)
      puts "Invalid input, please try again."
    end
    response
  end

  def set_first_move
    choice = choose_order
    self.first_to_move = if %w(yes y).include?(choice)
                           human.marker
                         elsif %w(no n).include?(choice)
                           computer.marker
                         else
                           [computer.marker, human.marker].sample
                         end
  end

  def set_computer_marker
    human.marker == 'X' ? 'O' : 'X'
  end

  def choose_marker
    clear
    response = ''
    loop do
      space_puts "Please enter a symbol to represent your marker:"
      response = gets.chomp.upcase
      break if response.strip.length == 1
      puts "Invalid input."
    end
    response
  end

  def ask_human_name
    clear
    name = ""
    loop do
      space_puts "What's your name?"
      name = gets.chomp.strip.capitalize
      break unless name.empty?
      puts "Sorry, must enter a value."
    end
    name
  end

  def display_welcome_message
    clear
    puts "* * * Welcome to Tic Tac Toe! * * *"
    puts
  end

  def display_goodbye_message
    clear
    puts "Thanks for playing Tic Tac Toe! Goodbye!"
  end

  def display_board
    space_puts "#{human.name} (#{human.marker}) vs. "\
               "#{computer.name} (#{computer.marker})"
    puts
    board.display
    puts
  end

  def clear_screen_and_display_board
    clear
    display_board
  end

  def update_scoreboard
    case board.winning_marker
    when human.marker
      scoreboard.human_wins += 1
    when computer.marker
      scoreboard.computer_wins += 1
    else # (nil)
      scoreboard.ties += 1
    end
  end

  def display_result
    clear_screen_and_display_board
    case board.winning_marker
    when human.marker
      puts "You won!"
    when computer.marker
      puts "#{computer.name} won!"
    else # (nil)
      puts "The board is full!"
    end
  end

  def play_again?
    answer = nil
    loop do
      space_puts "Would you like to play again? (y/n)"
      answer = gets.chomp.downcase
      break if %w(y n).include?(answer)
      puts "Sorry, must be y or n"
    end
    answer == 'y'
  end

  def reset
    board.reset
    alternate_first_to_move
    @current_marker = @first_to_move
    clear
  end

  def alternate_first_to_move
    self.first_to_move = if first_to_move == human.marker
                           computer.marker
                         else
                           human.marker
                         end
  end

  def display_play_again_message
    puts "Let's play again!"
    puts ""
  end

  def current_player_moves
    if human_turn?
      human.moves(board)
      @current_marker = computer.marker
    else
      pause
      computer.moves(board)
      @current_marker = human.marker
    end
  end

  def human_turn?
    @current_marker == human.marker
  end

  def set_grand_winner
    points = nil
    clear
    space_puts "How many points would you like to play to?"
    loop do
      points = gets.chomp.to_f
      break if points.to_i == points && points > 0
      puts "Sorry, please choose a positive integer."
    end
    self.grand_winner = points.to_i
  end

  def grand_winner?
    scoreboard.human_wins == grand_winner ||
      scoreboard.computer_wins == grand_winner
  end

  def display_grand_winner
    if scoreboard.human_wins == grand_winner
      space_puts "* * * Congratulations #{human.name}!"\
                 " You are the Grand-winner! * * *"
    else
      space_puts "* * * Sorry #{human.name} - "\
                 "#{computer.name} is the Grand-winner. * * *"
    end
  end

  def new_game
    self.computer = initialize_opponent
    set_grand_winner
    self.first_to_move = set_first_move
    self.current_marker = first_to_move
    self.scoreboard = Scoreboard.new(grand_winner)
  end
end

game = TTTGame.new
game.play
