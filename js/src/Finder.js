var Finder, Null, PAREN_REGEX, REGEX_FLAGS, Type, Void, assert, assertType, isType, type;

assertType = require("assertType");

isType = require("isType");

assert = require("assert");

Void = require("Void");

Null = require("Null");

Type = require("Type");

PAREN_REGEX = /(\(|\))/g;

REGEX_FLAGS = {
  global: "g",
  ignoreCase: "i",
  multiline: "m"
};

type = Type("Finder", function(target) {
  this.target = target;
  return this.next();
});

type.optionTypes = {
  regex: [RegExp, String, Null, Void],
  target: [String, Null, Void]
};

type.createArguments(function(args) {
  if (isType(args[0], Finder.optionTypes.regex)) {
    args[0] = {
      regex: args[0]
    };
  }
  return args;
});

type.exposeGetters(["groups"]);

type.defineValues({
  _groups: function() {
    return [];
  }
});

type.defineProperties({
  target: {
    value: null,
    willSet: function(newValue) {
      assertType(newValue, Finder.optionTypes.target);
      this.offset = 0;
      return newValue;
    }
  },
  pattern: {
    get: function() {
      return this._regex.source;
    },
    set: function(newValue) {
      var flags;
      newValue = newValue.replace("\\", "\\\\");
      flags = {
        global: true
      };
      if (this._regex) {
        if (this._regex.multiline) {
          flags.multiline = true;
        }
        if (this._regex.ignoreCase) {
          flags.ignoreCase = true;
        }
      }
      return this._regex = this._createRegex(newValue, flags);
    }
  },
  group: {
    value: 0,
    willSet: function(newValue) {
      assertType(newValue, Number);
      return newValue;
    }
  },
  offset: {
    get: function() {
      return this._regex.lastIndex;
    },
    set: function(newValue) {
      assertType(newValue, Number);
      assert(newValue >= 0, "'offset' must be >= 0!");
      return this._regex.lastIndex = newValue;
    }
  },
  _regex: {
    value: null,
    willSet: function(newValue) {
      var flags;
      assertType(newValue, Finder.optionTypes.regex);
      if (newValue == null) {
        return RegExp("");
      }
      if (isType(newValue, String)) {
        this.pattern = newValue;
        return this._regex;
      }
      if (!newValue.global) {
        flags = {
          global: true
        };
        if (newValue.multiline) {
          flags.multiline = true;
        }
        if (newValue.ignoreCase) {
          flags.ignoreCase = true;
        }
        return this._createRegex(newValue.source, flags);
      }
      return newValue;
    },
    didSet: function(newValue, oldValue) {
      this.offset = 0;
      if ((oldValue === null) || (newValue.source !== oldValue.source)) {
        return this._groups = this._parseRegexGroups(newValue.source);
      }
    }
  }
});

type.willBuild(function() {
  var flagProps;
  flagProps = {};
  ["multiline", "ignoreCase"].forEach(function(flag) {
    return flagProps[flag] = {
      get: function() {
        return this._regex[flag];
      },
      set: function(newValue) {
        var flags;
        assertType(newValue, Boolean);
        if (this._regex[flag] === newValue) {
          return;
        }
        flags = this._parseRegexFlags(this._regex);
        if (newValue) {
          flags[flag] = newValue;
        } else {
          delete flags[flag];
        }
        return this._regex = this._createRegex(this.pattern, flags);
      }
    };
  });
  return type.defineProperties(flagProps);
});

type.initInstance(function(options) {
  this._regex = options.regex;
  this.group = options.group != null ? options.group : options.group = this._groups.length > 1 ? 1 : 0;
  if (options.target != null) {
    return this.target = options.target;
  }
});

type.defineMethods({
  next: function() {
    var match, result;
    if (this.offset < 0) {
      return null;
    }
    match = this._regex.exec(this.target);
    assert(this.group < this.groups.length, {
      group: this.group,
      groups: this.groups,
      reason: "Index of capturing group is out of bounds!"
    });
    result = null;
    if (match != null) {
      if (this.group === null) {
        result = match.slice(1);
        result.index = match.index;
        result.string = match[0];
      } else {
        result = match[this.group];
      }
    }
    if (result != null) {
      return result;
    }
    this._regex.lastIndex = -1;
    return null;
  },
  each: function(target, iterator) {
    if (arguments.length === 1) {
      iterator = target;
      target = this.target;
    }
    assertType(target, String);
    assertType(iterator, Function);
    return this._each(target, iterator);
  },
  map: function(target, iterator) {
    var results;
    if (arguments.length === 1) {
      iterator = target;
      target = this.target;
    }
    assertType(target, String);
    assertType(iterator, Function);
    results = [];
    this._each(target, function(match, index) {
      return results.push(iterator(match, index));
    });
    return results;
  },
  all: function(target) {
    var matches;
    if (target == null) {
      target = this.target;
    }
    assertType(target, String);
    matches = [];
    this._each(target, function(match) {
      return matches.push(match);
    });
    return matches;
  },
  test: function(target) {
    assertType(target, String);
    return this._withTarget(target, (function(_this) {
      return function() {
        var match;
        match = _this._regex.exec(target);
        return match != null;
      };
    })(this));
  },
  _each: function(target, iterator) {
    return this._withTarget(target, (function(_this) {
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
      };
    })(this));
  },
  _parseRegexGroups: function(pattern) {
    var groupIndex, groups, match, paren, parens;
    assertType(pattern, String);
    parens = [];
    groups = [pattern];
    groupIndex = 0;
    PAREN_REGEX.lastIndex = 0;
    while (true) {
      match = PAREN_REGEX.exec(pattern);
      if (!match) {
        break;
      }
      if (pattern[PAREN_REGEX.lastIndex - 2] === "\\") {
        continue;
      }
      if (match[0] === "(") {
        parens.push({
          index: PAREN_REGEX.lastIndex,
          group: ++groupIndex
        });
      } else {
        assert(parens.length, "Unexpected right parenthesis!");
        paren = parens.pop();
        groups[paren.group] = pattern.slice(paren.index, PAREN_REGEX.lastIndex - 1);
      }
    }
    return groups;
  },
  _parseRegexFlags: function(regex, flags) {
    var flag, name;
    if (flags == null) {
      flags = {};
    }
    assertType(regex, [RegExp, Object]);
    assertType(flags, Object);
    for (name in REGEX_FLAGS) {
      flag = REGEX_FLAGS[name];
      if (regex[name] === true) {
        flags[flag] = true;
      } else if (regex[name] === false) {
        delete flags[flag];
      }
    }
    return flags;
  },
  _createRegex: function(pattern, flags) {
    assertType(pattern, String);
    assertType(flags, Object);
    flags = this._parseRegexFlags(flags);
    flags = Object.keys(flags).join("");
    return RegExp(pattern, flags);
  },
  _withTarget: function(target, callback) {
    var lastOffset, lastTarget, result;
    lastTarget = this.target;
    lastOffset = this.offset;
    this.target = target;
    result = callback();
    this.target = lastTarget;
    if (lastOffset !== null) {
      this._regex.lastIndex = lastOffset;
    }
    return result;
  }
});

type.defineStatics({
  find: function(regex, target, group) {
    var finder;
    finder = Finder._finder;
    finder._regex = regex;
    finder.group = group != null ? group : 0;
    return finder(target);
  },
  test: function(regex, target, group) {
    var finder;
    finder = Finder._finder;
    finder._regex = regex;
    finder.group = group != null ? group : 0;
    return finder.test(target);
  },
  _finder: {
    lazy: function() {
      return Finder(null);
    }
  }
});

module.exports = Finder = type.build();

//# sourceMappingURL=../../map/src/Finder.map
