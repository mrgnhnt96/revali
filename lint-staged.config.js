module.exports = {
    '**/*.+(json|mdx|md|js|jsx|ts|tsx|css|yml|yaml|xml)': (filesArray) => {
        const files = filesArray.join(' ');
        return [`pnpm exec prettier --write ${files}`];
    },
};
