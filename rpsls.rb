require 'yaml'
PROMPTS = YAML.load_file('rpsls_prompts.yml')

# User Interface module
module UI
  def enter_to_continue
    space_center PROMPTS["enter"]
    gets
    clear
  end

  def pause
    sleep 1
  end

  def clear
    system 'clear'
  end

  def center(input)
    puts input.center(100)
  end

  def space_puts(input)
    puts
    puts input
  end

  def space_center(input)
    puts
    center input
  end
end

# Player classes
class Player
  include UI
  attr_reader :move, :name

  def initialize
    set_name
  end

  private

  attr_writer :name

  def move=(choice)
    @move = case choice
            when 'rock' then Rock.new(choice)
            when 'paper' then Paper.new(choice)
            when 'scissors' then Scissors.new(choice)
            when 'lizard' then Lizard.new(choice)
            when 'spock' then Spock.new(choice)
            end
  end
end

# Human subclass of Player
class Human < Player
  def choose
    clear
    choice = nil
    loop do
      space_puts PROMPTS["choose_move"]
      choice = convert_abbreviation(gets.chomp.downcase)
      break if Move::VALUES.include?(choice)
      puts PROMPTS["invalid"]
    end
    self.move = choice
  end

  private

  def set_name
    n = ""
    loop do
      center PROMPTS["ask_name"]
      n = gets.chomp.strip.capitalize
      break unless n.empty?
      puts PROMPTS["sorry"]
    end
    self.name = n
  end

  def convert_abbreviation(choice)
    return choice if choice.size > 2
    case choice
    when 'r' then 'rock'
    when 'p' then 'paper'
    when 'sc' then 'scissors'
    when 'l' then 'lizard'
    when 'sp' then 'spock'
    end
  end
end

# Computer subclass of Player
class Computer < Player
  def choose(human_move)
    self.move = opponent.choose(human_move)
  end

  private

  attr_reader :opponent

  def set_name
    # @opponent references object of Computer subclass, ex. R2D2.new
    @opponent = set_opponent
    @name = opponent.name
  end

  def set_opponent # initializing an object from a Computer subclass
    choice = choose_opponent
    self.name = case choice
                when '1' then R2D2.new('R2D2')
                when '2' then Hal.new('Hal')
                when '3' then Bender.new('Bender')
                when '4' then Walle.new('WALL-E')
                when '5' then DjRoomba.new('DJ Roomba')
                end
  end

  def choose_opponent # user chooses their opponent
    clear
    choice = ""
    loop do
      center PROMPTS["choose_opponent"]
      space_center PROMPTS["opponents"]
      choice = gets.chomp
      break if %w(1 2 3 4 5).include?(choice)
      space_puts PROMPTS["invalid"]
    end
    choice
  end
end

# R2D2 subclass of Computer / Player
class R2D2 < Computer
  def initialize(name)
    @name = name
  end

  def choose(*) # R2D2 chooses randomly amongst all options
    choice = %w(rock paper scissors lizard spock).sample
    self.move = choice
  end
end

# Hal subclass of Computer / Player
class Hal < Computer
  def initialize(name)
    @name = name
  end

  def choose(*) # Hal usually chooses rock, but occasionally spock
    choice = %w(rock rock rock rock spock).sample
    self.move = choice
  end
end

# Bender subclass of Computer / Player
class Bender < Computer
  def initialize(name)
    @name = name
  end

  def choose(human_move) # Bender will always defeat the user
    choice = case human_move.to_s
             when 'rock' then %w(paper spock).sample
             when 'paper' then %w(scissors lizard).sample
             when 'scissors' then %w(rock spock).sample
             when 'lizard' then %w(rock scissors).sample
             when 'spock' then %w(lizard paper).sample
             end
    self.move = choice
  end
end

# WALL-E subclass of Computer / Player
class Walle < Computer
  def initialize(name)
    @name = name
  end

  def choose(human_move) # WALL-E will always be defeated by the user
    choice = case human_move.to_s
             when 'rock' then %w(scissors lizard).sample
             when 'paper' then %w(rock spock).sample
             when 'scissors' then %w(paper lizard).sample
             when 'lizard' then %w(spock paper).sample
             when 'spock' then %w(scissors rock).sample
             end
    self.move = choice
  end
end

# DJ Roomba subclass of Computer / Player
class DjRoomba < Computer
  def initialize(name)
    @name = name
  end

  def choose(human_move) # DJ Roomba will never tie with human
    choice = ''
    loop do
      choice = %w(rock paper scissors lizard spock).sample
      break if choice != human_move.to_s
    end
    self.move = choice
  end
end

# Move classes
class Move
  attr_reader :type

  VALUES = [
    'rock', 'paper', 'scissors', 'lizard', 'spock',
    'r', 'p', 'sc', 'l', 'sp'
  ]

  def initialize(type)
    @type = type
  end

  def to_s
    type
  end
end

# Rock subclass of Move
class Rock < Move
  def >(other_move)
    %w(lizard scissors).include?(other_move.type)
  end
end

# Paper subclass of Move
class Paper < Move
  def >(other_move)
    %w(rock spock).include?(other_move.type)
  end
end

# Scissors subclass of Move
class Scissors < Move
  def >(other_move)
    %w(lizard paper).include?(other_move.type)
  end
end

# Lizard subclass of Move
class Lizard < Move
  def >(other_move)
    %w(spock paper).include?(other_move.type)
  end
end

# Spock subclass of Move
class Spock < Move
  def >(other_move)
    %w(rock scissors).include?(other_move.type)
  end
end

# Scoreboard class - keeping track of score, displaying score
class Scoreboard
  include UI
  attr_accessor :human_wins, :computer_wins, :ties

  def initialize
    @human_wins = 0
    @computer_wins = 0
    @ties = 0
  end

  def display(human_name, computer_name, grand_winner)
    update_message(human_name, computer_name)
    space_puts [banner, horizontal_rule,
                empty_line, message_line, empty_line,
                horizontal_rule].join("\n")
    puts "First player to get #{grand_winner} "\
         "wins is the Grand-winner!".center((@message.size + 4))
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
    "* * * Scoreboard * * *".center((@message.size + 4))
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

# History class - logging and displaying past moves
class History
  include UI
  @@past_moves = {} # class variables log past moves and keep track of round
  @@round = 0

  # each round of the game initializes a new History object
  def initialize(human_move, computer_move)
    @human_move = human_move
    @computer_move = computer_move
    @@round += 1
    @@past_moves[@@round] = [@human_move, @computer_move]
  end

  def self.display(human_name, computer_name)
    system 'clear'
    puts "* * * #{human_name} vs. #{computer_name} * * *".center(40)
    puts "----------------------------------------"
    @@past_moves.each_pair do |round, moves|
      puts "Round #{round}: #{human_name} chose #{moves[0]}, "\
           "#{computer_name} chose #{moves[1]}"
    end
  end

  def self.clear_history
    @@past_moves = {}
    @@round = 0
  end
end

# RPSGame class: Game Orchestration Engine
class RPSGame
  include UI

  def initialize
    banner
    @human = Human.new
    @computer = Computer.new
    @scoreboard = Scoreboard.new
    @round = 1
  end

  # gameplay outer loop - game setup, invoke game_loop, asks to play again
  def play
    game_setup # invokes several pre-game methods asking for user input
    loop do
      game_loop
      display_grand_winner
      ask_history
      break unless play_again?
      new_game
    end
    display_goodbye_message
  end

  private

  attr_accessor :human, :computer, :scoreboard, :round, :grand_winner

  # gameplay inner loop - runs until a player wins
  def game_loop
    loop do
      human.choose
      computer.choose(human.move)
      display_moves
      game_results # invokes several Scoreboard and History class methods
      break if grand_winner?
      enter_to_continue
    end
  end

  def game_setup
    display_welcome_message
    ask_rules
    set_grand_winner
  end

  def game_results
    winner = determine_winner
    display_winner(winner)
    update_scoreboard(winner)
    scoreboard.display(human.name, computer.name, grand_winner)
    update_history
  end

  def banner
    clear
    space_center PROMPTS["banner"]
    puts
    enter_to_continue
  end

  def display_welcome_message
    clear
    space_center "Welcome to Rock, Paper, Scissors,"\
                 " Lizard, Spock #{human.name}!"
    space_center "* * * * * * * * * * * * * * * * "
    center "Today's game: #{human.name} vs. #{computer.name}"
    center "* * * * * * * * * * * * * * * * "
  end

  def set_grand_winner
    points = nil
    clear
    space_center PROMPTS["points"]
    loop do
      points = gets.chomp.to_f
      break if points.to_i == points && points > 0
      center PROMPTS["integer"]
    end
    self.grand_winner = points.to_i
  end

  def display_goodbye_message
    clear
    puts PROMPTS["thank_you"]
    puts
  end

  def display_moves
    clear
    space_puts "#{human.name} chose #{human.move}."
    sleep 1
    space_puts "#{computer.name} chose #{computer.move}."
  end

  def determine_winner
    if human.move > computer.move
      'human'
    elsif computer.move > human.move
      'computer'
    else
      'tie'
    end
  end

  def display_winner(winner)
    pause
    puts
    case winner
    when 'human' then puts "#{human.name} wins this round!"
    when 'computer' then puts "#{computer.name} wins this round!"
    when 'tie' then puts "This round is a tie."
    end
  end

  def update_scoreboard(winner)
    case winner
    when 'human' then scoreboard.human_wins += 1
    when 'computer' then scoreboard.computer_wins += 1
    when 'tie' then scoreboard.ties += 1
    end
  end

  def update_history
    History.new(human.move.to_s, computer.move.to_s)
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
      space_puts "* * * Sorry #{human.name} -"\
                 " #{computer.name} is the Grand-winner. * * *"
    end
  end

  def ask_history
    space_puts PROMPTS["ask_history"]
    response = validate_yes_or_no
    return unless ['yes', 'y'].include?(response)
    History.display(human.name, computer.name)
  end

  def ask_rules
    space_center PROMPTS["ask_rules"]
    response = validate_yes_or_no
    display_rules if ['yes', 'y'].include?(response)
    clear if ['no', 'n'].include?(response)
  end

  def display_rules
    clear
    space_center PROMPTS["rules"]
    puts
    enter_to_continue
  end

  def validate_yes_or_no
    response = ''
    loop do
      response = gets.chomp.downcase
      break if ['yes', 'no', 'y', 'n'].include?(response)
      center "Invalid input. Please repond (y / n)"
    end
    response
  end

  def new_game
    self.computer = Computer.new
    self.scoreboard = Scoreboard.new
    self.round = 1
    History.clear_history
    set_grand_winner
  end

  def play_again?
    space_puts PROMPTS["ask_play_again"]
    response = validate_yes_or_no
    ['yes', 'y'].include?(response)
  end
end

RPSGame.new.play # invokes gameplay loop
