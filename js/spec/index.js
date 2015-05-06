(function() {
  describe("Finder", function() {
    describe("(constructor)", function() {
      it("accepts a RegExp", function() {
        var error, find;
        try {
          return find = Finder(/foo/);
        } catch (_error) {
          error = _error;
          return expect(error).toBeFalsy();
        }
      });
      it("accepts a String", function() {
        var error, find;
        try {
          return find = Finder("foo");
        } catch (_error) {
          error = _error;
          return expect(error).toBeFalsy();
        }
      });
      it("fails if not a RegExp or String", function() {
        var error, find;
        try {
          return find = Finder();
        } catch (_error) {
          error = _error;
          return expect(error).toBeTruthy();
        }
      });
      return describe("(aftermath)", function() {
        var find;
        find = null;
        beforeAll(function() {
          return find = Finder("foo");
        });
        it("sets the 'regex' property", function() {
          return expect(find.regex.source).toBe("foo");
        });
        it("sets the 'group' property", function() {
          return expect(find.group).toBe(1);
        });
        return it("sets the '__proto__' property", function() {
          return expect(find.__proto__).toBe(Finder.prototype);
        });
      });
    });
    describe("@()", function() {
      return describe("(aftermath)", function() {
        var find, regex, result, string;
        regex = find = string = result = null;
        beforeAll(function() {
          regex = /foo/;
          find = Finder(regex);
          string = "all you need is foo";
          return result = find(string);
        });
        it("sets the 'string' property", function() {
          return expect(find.string).toBe(string);
        });
        it("returns the first match", function() {
          return expect(result).toBe(regex.source);
        });
        return it("resets the 'regex.lastIndex' property", function() {
          expect(regex.lastIndex).not.toBe(0);
          find(string);
          return expect(regex.lastIndex).toBe(0);
        });
      });
    });
    describe("@next()", function() {
      var find;
      find = null;
      beforeAll(function() {
        find = Finder("[a-z]+");
        return find.string = "a b c";
      });
      it("increments the 'offset' property", function() {
        find.next();
        return expect(find.offset).toBe(1);
      });
      it("returns the next match", function() {
        expect(find.next()).toBe("b");
        return expect(find.next()).toBe("c");
      });
      return it("returns null if no other matches exist", function() {
        return expect(find.next()).toBe(null);
      });
    });
    describe("@all()", function() {
      var find, first, matches;
      find = first = matches = null;
      beforeAll(function() {
        find = Finder("[a-z]+");
        first = find("11 aa b cc 00");
        return matches = find.all();
      });
      it("returns all matches found", function() {
        return expect(matches).toEqual(["aa", "b", "cc"]);
      });
      return it("doesnt fuck up the 'offset' property", function() {
        return expect(find.offset).toBe(first.length);
      });
    });
    return describe("@test()", function() {
      var find;
      find = null;
      beforeAll(function() {
        return find = Finder("[a-z]+");
      });
      it("returns true when the 'regex' property finds a match in the given String", function() {
        return expect(finder.test("a b c")).toBe(true);
      });
      return it("returns false when the 'regex' property fails to find a match in the given String", function() {
        return expect(finder.test("1 2 3")).toBe(false);
      });
    });
  });

}).call(this);

//# sourceMappingURL=map/index.js.map
