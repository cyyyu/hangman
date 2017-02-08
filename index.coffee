'use strict'

#####################################################################################
###
  # Dependicies  
###
request = require 'request'
checker = require './lib/word-resolver'
_ = require 'lodash'
colors = require 'colors'


#####################################################################################
###
  # Define some helpers.  
###
print = ->
  console.log.apply null, _.toArray(arguments).concat '\n======================================'.grey

# 
always = (val) -> -> val

# Constants
api = always 'https://strikingly-hangman.herokuapp.com/game/on'
letters = always 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'

# Is a word completly unknown?
isCompletlyUnknown = (word) ->
  _.every _.map word, (val) ->
    val is '*'
  , Boolean

# Pick a random letter
pickRandomLetter = (i) ->
  return i[_.random(0, i.length - 1)]

# Remove items that have used.
rmUsed = (target, used) ->
  re = _.map target, (val) ->
    if val and (not ((used.indexOf val) > -1))
      return val
    else
      return ''
  return re.join ''

# Pick a possible letter.
pickALetter = (word, guessedLetters) ->
  new Promise (resolve, reject) ->
    if isCompletlyUnknown word
      l = _.reduce letters(), (sum, val) ->
        if not ((guessedLetters.indexOf val) > -1)
          return sum + val
        else
          return sum
      randomLetter = pickRandomLetter l
      resolve randomLetter
    else
      checker word
      .then (possibleWords) ->
        hints = word.replace '*', ''
        s = _.toUpper _.reduce possibleWords, (sum, val) ->
          sum += val
          re = rmUsed (_.toUpper sum), (_.toUpper guessedLetters)
          return re
        print 'Possible letters: '.cyan, s
        resolve pickRandomLetter s

# Should I ask for next word?
shouldAskNextWord = (times, word)->
  if not word
    return true
  else
    left = (word.match /\*/g)?.length or -9999
    return (times >= 10) or ((10 - times) < left) or (not /\*/g.test word)

# Use api
send = (action, data) ->
  post = (resolve) ->
    request.post api(), {
        json: Object.assign {
            action: action
          }, data
      }, (err, data) ->
        if err or (not data.body.data)
          print 'Network error, game over.'.red, err
          # throw new Error 'Network error or data error.'
          # retry
          post resolve
        else
          resolve data.body

  return new Promise post

#####################################################################################
###
  # Define Player class. 
###
class Player
  constructor: (@id, @targetScore) ->
    @status =
      word: ''
      guessedLetters: ''
      on: yes

  StartGame: ->
    _this = this

    send 'startGame', {
        playerId: _this.id
      }
    .then (re) ->
      print 'The game is on.'.green, re.data
      _this.session = re.sessionId

      _this.getNextWord()

  getNextWord: ->
    _this = this

    if not _this.status.on
      return

    send 'nextWord', {
        sessionId: _this.session
      }
    .then (re) ->
      print 'Got a new word.'.bgCyan, re.data

      _this.resetWord re.data.word
      _this.resetGuessedLetters ''

      _this.showScore()

      _this.guess()
  
  showScore: ->
    _this = this
    send 'getResult', {
        sessionId: _this.session        
      }
    .then (re) ->
      print 'Now score: '.bgRed, re.data

      if re.data.score >= _this.targetScore
        _this.submit re.data.score

  guess: ->
    _this = this

    if not _this.status.on
      return

    pickALetter _this.status.word, _this.status.guessedLetters
    .then (possibleLetter) ->
      print 'Guess: '.bgMagenta, possibleLetter
      send 'guessWord', {
          guess: possibleLetter
          sessionId: _this.session
        }
      .then (re)->
        print 'Guess result: '.bgBlue, re.data.word, '. Times left: ', 10 - re.data.wrongGuessCountOfCurrentWord

        _this.mergeGuessedLetter possibleLetter

        _this.resetWord re.data.word

        if shouldAskNextWord re.data.wrongGuessCountOfCurrentWord, re.data.word
          _this.getNextWord()
        else
          _this.guess()
    .catch (err)->
      print 'Pick letter error.'.red, err
      _this.getNextWord()

  mergeGuessedLetter: (letter) ->
    _this = this
    _this.status.guessedLetters += letter
    print 'Guessed letters: ', _this.status.guessedLetters

  resetWord: (word) ->
    _this = this
    _this.status.word = word || ''

  resetGuessedLetters: (letters) ->
    _this = this
    _this.status.guessedLetters = letters || ''
    print 'resetGuessedletter', _this.status.guessedLetters

  submit: ->
    _this = this
    send 'submitResult', {
        sessionId: _this.session
      }
    .then (re)->
      print re.data
      _this.status.on = no

#####################################################################################
# Exports
exports = module.exports = Player