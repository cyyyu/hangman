'use strict'

###
  # Dependicies
###
request = require 'request'
_ = require 'lodash'

# api
api = -> 'http://www.hanginghyena.com/gateway/lookup'

# the module
checker = (word) ->
  new Promise (resolve, reject) ->
    request.post api(), {
        json: yes
        form:
          pattern: _.replace word, '*', '?'
          exclusions: ''
      }
      , (err, re)->
        if err
          reject err
        else
          data = _.keys re.body.words
          resolve data.sort()

# exports
exports = module.exports = checker