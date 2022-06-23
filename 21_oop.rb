module Flowable
  def enter_to_continue
    space_puts "Press enter to continue..."
    gets
    clear
  end

  def pause
    sleep 2
  end

  def clear
    system 'clear'
  end

  def space_puts(input)
    puts
    puts input
  end

  def get_input(question, valid_input)
    answer = nil
    loop do
      space_puts question
      answer = gets.chomp.strip.downcase
      return answer if valid_input.include?(answer)
      space_puts "Sorry, invalid input."
    end
  end

  def show_rules
    clear
    puts GAME_INFO
    enter_to_continue
  end

  GAME_INFO = <<-MSG

  *** A Guide to 21 ***

  The goal of 21 is to try to get your hand's total
  as close to 21 as possible, without going over.
  If you go over 21, it's called a "bust" and you lose.

  Card Values:
  2 - 10 = face value
  Jack, Queen, King = 10
  Ace = 1 or 11 (depending on the total of your hand)

  Gameplay: You start with two cards and then must decide
  whether to hit or stay. If you hit, the value of the new card
  is added to your total. The dealer will show you one of their
  cards to aid in your strategy.

  If nobody busts, the your cards are compared to the dealer's
  cards, and whoever has a higher total wins!

  MSG
end

class Deck
  SUITS = %i(♠️ ♥️ ♦️ ♣️)
  VALUES = %w(2 3 4 5 6 7 8 9 10 King Queen Jack Ace)

  def initialize
    @cards = SUITS.product(VALUES).shuffle
  end

  def deal
    card = @cards.pop
    Card.new(card[0], card[1])
  end
end

class Card
  attr_reader :suit, :value

  def initialize(suit, value)
    @suit = suit
    @value = value
  end

  def to_s
    " - #{suit} #{value}"
  end
end

class Participant
  include Flowable
  attr_accessor :hand, :name

  def initialize(name = nil)
    @hand = []
    @name = name
  end

  def hit_sequence(deck)
    hit(deck)
    display_hit
  end

  def hit(deck)
    hand << deck.deal
  end

  def display_hand
    hand.each { |card| puts card }
  end

  def busted?
    total > Game::LIMIT
  end

  def total
    values = hand.map(&:value)
    sum = 0
    values.each { |value| sum += find_card_value(value) }
    sum = correct_total_for_aces(values, sum)
  end

  def to_s
    name
  end

  def >(other)
    total > other.total
  end

  def <(other)
    total < other.total
  end

  private

  def correct_total_for_aces(values, sum)
    values.select { |value| value == 'Ace' }.count.times do
      sum -= 10 if sum > Game::LIMIT
    end
    sum
  end

  def find_card_value(value)
    return 11 if value == 'Ace'
    return 10 if %w(King Queen Jack).include?(value)
    value.to_i
  end
end

class Player < Participant
  def set_name
    name = ""
    loop do
      space_puts "Please enter your name:"
      name = gets.chomp.strip.capitalize
      break unless name.empty?
      puts "Sorry, must enter a value."
    end
    self.name = name
  end

  def turn(deck)
    loop do
      input = ask_hit_or_stay
      if %w(h hit).include?(input)
        hit_sequence(deck)
        return if busted?
      else
        display_stay
        return
      end
    end
  end

  def ask_hit_or_stay
    question = "Would you like to (h)it or (s)tay?"
    response = get_input(question, %w(h s hit stay))
    response
  end

  def display_hit
    space_puts "Dealing..."
    pause
    space_puts "You have been dealt"
    puts hand.last
    pause
    puts "Your new total is #{total}"
  end

  def display_stay
    clear
    space_puts "You chose to stay - your total is #{total}"
  end
end

class Dealer < Participant
  DEALERS = ['DJ Roomba', 'Bender', 'R2D2', 'Hal', 'WALL-E']

  def set_name
    self.name = DEALERS.sample
  end

  def turn(deck)
    space_puts "Now it's the dealer's turn..."
    loop do
      thinking_message
      hit_sequence(deck) if total < Game::DEALER_MINIMUM
      return if busted?
      display_stay if total >= Game::DEALER_MINIMUM
      return if total >= Game::DEALER_MINIMUM
    end
  end

  def thinking_message
    pause
    space_puts "#{name} is thinking..."
    pause
  end

  def display_hit
    space_puts "#{name} chose to hit!"
    puts "#{name}'s new total is #{total}"
  end

  def display_stay
    space_puts "#{name} chose to stay - #{name}'s total is #{total}"
  end

  def display_one_card
    puts hand.first
  end
end

class Scoreboard
  include Flowable
  attr_accessor :player_wins, :dealer_wins, :ties, :grand_winner

  def initialize
    @player_wins = 0
    @dealer_wins = 0
    @ties = 0
  end

  def display(player_name, dealer_name, grand_winner)
    update_message(player_name, dealer_name)
    space_puts [banner(grand_winner), horizontal_rule,
                empty_line, message_line, empty_line,
                horizontal_rule].join("\n")
  end

  def update(player_total, dealer_total)
    if player_total > Game::LIMIT || dealer_total > Game::LIMIT
      update_when_busted(player_total)
    elsif player_total > dealer_total
      self.player_wins += 1
    elsif dealer_total > player_total
      self.dealer_wins += 1
    else
      self.ties += 1
    end
  end

  protected

  def update_message(player_name, dealer_name)
    self.message =
      "#{player_name}'s wins: #{player_wins}       "\
      "#{dealer_name}'s wins:  #{dealer_wins}       "\
      "Ties: #{ties}".center(60)
  end

  private

  attr_accessor :message

  def update_when_busted(player_total)
    player_total > Game::LIMIT ? self.dealer_wins += 1 : self.player_wins += 1
  end

  def banner(grand_winner)
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

class Game
  include Flowable

  def initialize(grand_winner = nil, scoreboard = nil)
    @deck = Deck.new
    @player = Player.new
    @dealer = Dealer.new
    @grand_winner = grand_winner
    @scoreboard = scoreboard
  end

  def play
    game_setup
    loop do # allows user to choose to play again
      game_play_loop
      display_grand_winner
      scoreboard.display(player.name, dealer.name, grand_winner)
      break unless play_again?
      final_reset
    end
    goodbye_message
  end

  private

  LIMIT = 21
  NAME_OF_GAME = 21
  DEALER_MINIMUM = 17

  attr_accessor :scoreboard, :grand_winner, :deck
  attr_reader :player, :dealer

  def game_play_loop # breaks if there is a grand_winner
    loop do
      single_round
      scoreboard.update(player.total, dealer.total)
      display_both_hands
      enter_to_continue
      return if grand_winner?
      if_no_grand_winner
    end
  end

  def single_round
    deal_cards
    display_initial_cards
    participants_take_turns
    return if dealer.busted? || player.busted?
    display_winner
  end

  def if_no_grand_winner
    scoreboard.display(player.name, dealer.name, grand_winner)
    enter_to_begin_next_round
    reset
  end

  def participants_take_turns
    player.turn(deck)
    if_participant_busts(player)
    return if player.busted?
    dealer.turn(deck)
    if_participant_busts(dealer)
    return if dealer.busted?
  end

  def if_participant_busts(participant)
    return unless participant.busted?
    busted_message
  end

  def game_setup
    welcome_message
    set_participant_names
    ask_to_view_rules
    set_grand_winner
    initialize_scoreboard
  end

  def set_grand_winner
    question = "How many points would you like to play to? (1-5)"
    points = get_input(question, '1'..'5')
    self.grand_winner = points.to_i
  end

  def initialize_scoreboard
    self.scoreboard = Scoreboard.new
  end

  def set_participant_names
    player.set_name
    dealer.set_name
  end

  def deal_cards
    clear
    2.times { player.hand << deck.deal }
    2.times { dealer.hand << deck.deal }
  end

  def display_winner
    pause
    clear
    if player > dealer
      puts "* * * You win this round! * * *"
    elsif dealer > player
      puts "* * * #{dealer} wins this round! * * *"
    else
      puts "* * * This round is a tie * * *"
    end
  end

  def display_initial_cards
    puts "#{player} has #{player.hand.size} cards:"
    puts "---------------------"
    player.display_hand
    space_puts "#{dealer} (the dealer) has #{dealer.hand.size} cards:"
    puts "---------------------"
    dealer.display_one_card
    puts " - (one hidden card)"
  end

  def busted_message
    pause
    clear
    player_busted = "* * * Oh no! You have busted - #{dealer} wins! * * *"
    dealer_busted = "* * * #{dealer} has busted - you win! * * *"
    player.busted? ? space_puts(player_busted) : space_puts(dealer_busted)
  end

  def play_again?
    question = "Would you like to play again? (y/n)"
    response = get_input(question, %w(y n yes no))
    response == 'y' || response == 'yes'
  end

  def reset
    player.hand = []
    dealer.hand = []
    self.deck = Deck.new
  end

  def final_reset
    player.hand = []
    dealer.hand = []
    self.deck = Deck.new
    self.scoreboard = Scoreboard.new
  end

  def goodbye_message
    clear
    puts "Thank you for playing - good bye."
    puts
  end

  def welcome_message
    clear
    puts "* * * Welcome to #{NAME_OF_GAME}! * * *"
  end

  def ask_to_view_rules
    answer = nil
    loop do
      space_puts "Would you like to see the rules: (Y)es or (N)o?"
      answer = gets.chomp.downcase
      break if %w(yes no y n).include?(answer)
      puts "Sorry, please enter 'yes', 'no', 'y', or 'n'"
    end
    show_rules if %w(yes y).include?(answer)
  end

  def display_both_hands
    space_puts "============ Final Hands ============"
    puts "You had:"
    player.display_hand
    puts "...for a total of #{player.total}"
    puts "====================================="
    puts "#{dealer} had:"
    dealer.display_hand
    puts "...for a total of: #{dealer.total}"
    puts "====================================="
  end

  def enter_to_begin_next_round
    space_puts "Press enter to begin next round..."
    gets
    clear
  end

  def grand_winner?
    scoreboard.player_wins == grand_winner ||
      scoreboard.dealer_wins == grand_winner
  end

  def display_grand_winner
    if scoreboard.player_wins == grand_winner
      space_puts "* * * Congratulations #{player}!"\
                 " You are the Grand-winner! * * *"
    else
      space_puts "* * * Sorry #{player} - "\
                 "#{dealer} is the Grand-winner. * * *"
    end
  end
end

Game.new.play
