//  modified from https://github.com/UziTech/marked-emoji 
//  to take a list of emojis and set class for unocss

const defaultOptions = {
  // emojis: [], required
  renderer: undefined,
};

export function markedEmoji(options) {
  options = {
    ...defaultOptions,
    ...options,
  };

  if (!options.emojis) {
    throw new Error('Must provide emojis to markedEmoji');
  }

  const emojiNames = options.emojis.map(e => e.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')).join('|');
  const emojiRegex = new RegExp(`:(${emojiNames}):`);
  const tokenizerRule = new RegExp(`^${emojiRegex.source}`);

  return {
    extensions: [{
      name: 'emoji',
      level: 'inline',
      start(src) { return src.match(emojiRegex)?.index; },
      tokenizer(src, tokens) {
        const match = tokenizerRule.exec(src);
        if (!match) {
          return;
        }

        const name = match[1];

        return {
          type: 'emoji',
          raw: match[0],
          name,
        };
      },

      renderer(token) {
        if (options.renderer) {
          return options.renderer(token);
        }
        return `<div alt=${token.name}" class="i-openmoji-${token.name} text-3xl"></div>`
      },
    }],
  };
}
