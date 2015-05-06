
describe "Finder", ->

  describe "(constructor)", ->

    it "accepts a RegExp", ->
      try
        find = Finder /foo/
      catch error
        expect error
          .toBeFalsy()

    it "accepts a String", ->
      try
        find = Finder "foo"
      catch error
        expect error
          .toBeFalsy()

    it "fails if not a RegExp or String", ->
      try
        find = Finder()
      catch error
        expect error
          .toBeTruthy()

    describe "(aftermath)", ->

      find = null

      beforeAll ->
        find = Finder "foo"

      it "sets the 'regex' property", ->
        expect find.regex.source
          .toBe "foo"

      it "sets the 'group' property", ->
        expect find.group
          .toBe 1

      it "sets the '__proto__' property", ->
        expect find.__proto__
          .toBe Finder.prototype

  describe "@()", ->

    describe "(aftermath)", ->

      regex = find = string = result = null

      beforeAll ->
        regex = /foo/
        find = Finder regex
        string = "all you need is foo"
        result = find string

      it "sets the 'string' property", ->
        expect find.string
          .toBe string

      it "returns the first match", ->
        expect result
          .toBe regex.source

      it "resets the 'regex.lastIndex' property", ->
        expect regex.lastIndex
          .not.toBe 0
        find string  
        expect regex.lastIndex
          .toBe 0

  # describe "@offset", ->

    # it "defaults to 1 when at least one capture group exists", ->

    # it "defaults to 0 when no capture group exists", ->

    # it "determines the capturing group", ->
    #   find = Finder /([a-z]+) ([a-z]+)/
    #   find.offset = 2
    #   find

    # describe "It returns the whole matched substring if no capturing group exists in ", ->

    #   it "if no capturing group exists in the 'regex' property", ->

    #   it "if equal to zero", ->


  describe "@next()", ->

    find = null

    beforeAll ->
      find = Finder "[a-z]+"
      find.string = "a b c"

    it "increments the 'offset' property", ->
      find.next()
      expect find.offset
        .toBe 1

    it "returns the next match", ->
      expect find.next()
        .toBe "b"
      expect find.next()
        .toBe "c"

    it "returns null if no other matches exist", ->
      expect find.next()
        .toBe null

  describe "@all()", ->

    find = first = matches = null

    beforeAll ->
      find = Finder "[a-z]+"
      first = find "11 aa b cc 00"
      matches = find.all()

    it "returns all matches found", ->
      expect matches
        .toEqual ["aa", "b", "cc"]

    it "doesnt fuck up the 'offset' property", ->
      expect find.offset
        .toBe first.length

  describe "@test()", ->

    find = null

    beforeAll ->
      find = Finder "[a-z]+"

    it "returns true when the 'regex' property finds a match in the given String", ->
      expect finder.test "a b c"
        .toBe true

    it "returns false when the 'regex' property fails to find a match in the given String", ->
      expect finder.test "1 2 3"
        .toBe false

  # describe "@reduce()", ->

  #   finder = null

  #   beforeAll ->
  #     finder = Finder 
