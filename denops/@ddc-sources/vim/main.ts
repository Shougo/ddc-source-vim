import type {
  Context,
  DdcOptions,
  Item,
  Previewer,
  SourceOptions,
} from "@shougo/ddc-vim/types";
import { BaseSource } from "@shougo/ddc-vim/source";

import type { Denops } from "@denops/std";
import * as fn from "@denops/std/function";

type Params = Record<string, never>;

const variable = /[a-z]:([a-zA-Z_][a-zA-Z0-9_]*)?/;
const option = /\&([gl]:)?[a-zA-Z0-9_:]*/;
const plug = /<Plug>\([^)]*\)?/;
const expand = /<[a-zA-Z][a-zA-Z0-9_-]*>?/;
const func = /[a-zA-Z_][a-zA-Z0-9_:#]*[!(]?/;
const env = /\$[a-zA-Z_][a-zA-Z0-9_]*/;
const stringInterpolation = /(?<=\$["'].*{).*?(?=})/;

const keywordPattern = new RegExp(
  `(${variable.source}|${option.source}|${plug.source}|` +
    `${expand.source}|${func.source}|${env.source}|${stringInterpolation.source})$`,
);

export class Source extends BaseSource<Params> {
  override isBytePos = true;

  override async getCompletePosition(args: {
    denops: Denops;
    context: Context;
  }): Promise<number> {
    const curText = await args.denops.call(
      "ddc#source#vim#get_cur_text",
      args.context.input,
    ) as string;
    if (curText.match(/^\s*"/)) {
      // Comment
      return -1;
    }

    return args.context.input.search(keywordPattern);
  }

  override async gather(args: {
    denops: Denops;
    context: Context;
    options: DdcOptions;
    sourceOptions: SourceOptions;
    sourceParams: Params;
    completeStr: string;
  }): Promise<Item[]> {
    return await args.denops.call(
      "ddc#source#vim#gather",
      args.context.input,
      args.completeStr,
    ) as Item[];
  }

  override async getPreviewer(args: {
    denops: Denops;
    item: Item;
  }): Promise<Previewer> {
    const help = await fn.getcompletion(args.denops, args.item.word, "help");
    if (help.length === 0) {
      return {
        kind: "empty",
      };
    } else {
      return {
        kind: "help",
        tag: args.item.word,
      };
    }
  }

  override params(): Params {
    return {};
  }
}
