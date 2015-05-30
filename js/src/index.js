(function() {
  var Finder, _defaultFinder, _getGroups, _getRegexFlags, _parenRegex, _regexFlags, _regexWillBeSet, _setRegexFlags, _tempTarget, define, ref, setKind, setType, targetWillBeSet;

  require("../../../lotus-require");

  define = require("define");

  ref = require("type-utils"), setType = ref.setType, setKind = ref.setKind;

  Finder = module.exports = function(options) {
    var finder, regex;
    if ((options instanceof RegExp) || (typeof options === "string")) {
      regex = options;
      options = {
        regex: regex
      };
    }
    finder = function(target) {
      finder.target = target;
      return finder.next();
    };
    setType(finder, Finder);
    define(finder, function() {
      this.options = {
        configurable: false,
        enumerable: false
      };
      this({
        _groups: [],
        _regex: {
          assign: options.regex,
          willSet: _regexWillBeSet
        }
      });
      this.enumerable = true;
      return this({
        group: options.group || (finder.groups.length > 1 ? 1 : 0),
        target: {
          value: options.target || "",
          willSet: targetWillBeSet
        }
      });
    });
    return finder;
  };

  setKind(Finder, Function);

  define(Finder, function() {
    this.options = {
      configurable: false,
      writable: false
    };
    this({
      find: function(regex, target) {
        _defaultFinder._regex = regex;
        return _defaultFinder(target);
      },
      test: function(regex, target) {
        _defaultFinder._regex = regex;
        return _defaultFinder.test(target);
      }
    });
    return this(Finder.prototype, function() {
      var i, key, len, ref1, results;
      this({
        next: function() {
          var error, match, result;
          if (this.offset < 0) {
            return null;
          }
          match = this._regex.exec(this.target);
          if (!(this.group < this.groups.length)) {
            error = RangeError("'this.group' must be less than " + this.groups.length + ", but equaled " + this.group + ".");
            error.code = "BAD_GROUP";
            throw error;
          }
          result = null;
          if (match != null) {
            result = match[this.group];
          }
          if (result != null) {
            return result;
          }
          this._regex.lastIndex = -1;
          return null;
        },
        each: function(target, iterator) {
          if (typeof iterator !== "function" && typeof target === "function") {
            iterator = target;
          }
          if (typeof target !== "string") {
            target = this.target;
          }
          return _tempTarget.call(this, target, (function(_this) {
            return function() {
              var index, match;
              index = 0;
              while (true) {
                match = _this.next();
                if (match === null) {
                  break;
                }
                iterator(match, index++);
              }
              return null;
            };
          })(this));
        },
        map: function(target, iterator) {
          var map;
          map = [];
          this.each(target, function(match, index) {
            return map.push(iterator(match, index));
          });
          return map;
        },
        reduce: function(target, initial, iterator) {
          if (!(iterator instanceof Function)) {
            iterator = initial;
            initial = target;
            target = this.target;
          }
          this.each(target, function(match, index) {
            return initial = iterator(initial, match, index);
          });
          return initial;
        },
        all: function(target) {
          var matches;
          matches = [];
          this.each(target, function(match) {
            return matches.push(match);
          });
          return matches;
        },
        test: function(target) {
          var error;
          if (typeof target !== "string") {
            error = TypeError("'target' must be a String.");
            error.code = "BAD_TARGET_TYPE";
            throw error;
          }
          return _tempTarget.call(this, target, (function(_this) {
            return function() {
              var match;
              match = _this._regex.exec(target);
              return match != null;
            };
          })(this));
        },
        groups: {
          get: function() {
            return this._groups;
          }
        }
      });
      this.writable = true;
      this({
        offset: {
          get: function() {
            if (this._regex != null) {
              return this._regex.lastIndex;
            }
          },
          set: function(newValue) {
            var error;
            if (typeof newValue !== "number") {
              error = TypeError("'this.offset' must be a Number.");
              error.code = "BAD_OFFSET_TYPE";
              throw error;
            }
            if (newValue < 0) {
              error = RangeError("@offset must be >= 0");
              error.code = "";
              throw error;
            }
            return this._regex.lastIndex = newValue;
          }
        },
        pattern: {
          get: function() {
            if (this._regex != null) {
              return this._regex.source;
            }
          },
          set: function(newValue) {
            var flags;
            flags = _getRegexFlags(newValue, {});
            flags.g = true;
            flags = Object.keys(flags).join("");
            newValue = newValue.replace("\\", "\\\\");
            this._regex = RegExp(newValue, flags);
            return this.offset = 0;
          }
        }
      });
      ref1 = ["ignoreCase", "multiline"];
      results = [];
      for (i = 0, len = ref1.length; i < len; i++) {
        key = ref1[i];
        results.push(this(key, {
          get: function() {
            return this._regex[key];
          },
          set: function(newValue) {
            var newFlags;
            if (this._regex[key] === newValue) {
              return;
            }
            newFlags = {};
            newFlags[key] = newValue;
            return this._regex = _setRegexFlags(this._regex, newFlags);
          }
        }));
      }
      return results;
    });
  });


  /* PRIVATE VARS */

  targetWillBeSet = function(target) {
    var error;
    if (typeof target !== "string") {
      error = TypeError("'target' must be a String.");
      error.code = "BAD_TARGET_TYPE";
      throw error;
    }
    this.offset = 0;
    return target;
  };

  _parenRegex = /(\||\(|\))/g;

  _regexFlags = {
    global: "g",
    ignoreCase: "i",
    multiline: "m"
  };

  _regexWillBeSet = function(regex) {
    if (regex == null) {
      regex = "";
    }
    if (typeof regex === "string") {
      this.pattern = regex;
      return this._regex;
    } else if (regex instanceof RegExp) {
      regex = regex.global ? regex : _setRegexFlags(regex, {
        global: true
      });
      this._groups = _getGroups(regex);
      return regex;
    } else {
      throw TypeError("You must pass either a RegExp or String when setting @_regex.");
    }
  };

  _getRegexFlags = function(input, output) {
    var inputValue, key, value;
    for (key in _regexFlags) {
      value = _regexFlags[key];
      inputValue = input[key];
      if (inputValue === true) {
        output[value] = true;
      } else if (inputValue === false) {
        delete output[value];
      }
    }
    return output;
  };

  _setRegexFlags = function(regex, newFlags) {
    var flags, newRegex;
    flags = {};
    _getRegexFlags(regex, flags);
    _getRegexFlags(newFlags, flags);
    newRegex = RegExp(regex.source, Object.keys(flags).join(""));
    newRegex.lastIndex = regex.lastIndex;
    return newRegex;
  };

  _getGroups = function(regex) {
    var groupIndex, groups, match, paren, parens;
    parens = [];
    groups = [regex.source];
    groupIndex = 0;
    _parenRegex.lastIndex = 0;
    while (true) {
      match = _parenRegex.exec(regex.source);
      if (match == null) {
        break;
      }
      if (regex.source[_parenRegex.lastIndex - 2] === "\\") {
        continue;
      }
      switch (match[0]) {
        case "(":
          parens.push({
            index: _parenRegex.lastIndex,
            group: ++groupIndex
          });
          break;
        case ")":
          paren = parens.pop();
          if (paren == null) {
            continue;
          }
          groups[paren.group] = regex.source.slice(paren.index, _parenRegex.lastIndex - 1);
          break;
        case "|":
          parens.pop();
      }
    }
    return groups;
  };

  _tempTarget = function(target, fn) {
    var _offset, _target, result;
    _offset = this.offset;
    _target = this.target;
    this.target = target;
    result = fn();
    this.target = _target;
    this._regex.lastIndex = _offset;
    return result;
  };

  _defaultFinder = Finder("");

}).call(this);

//# sourceMappingURL=map/index.js.map
