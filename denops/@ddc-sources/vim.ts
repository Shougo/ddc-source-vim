import {
  BaseSource,
  DdcOptions,
  Item,
  SourceOptions,
} from "https://deno.land/x/ddc_vim@v4.1.0/types.ts";
import {
  Denops,
} from "https://deno.land/x/ddc_vim@v4.1.0/deps.ts";

type Params = Record<string, never>;

export class Source extends BaseSource<Params> {
  override async gather(_args: {
    denops: Denops;
    options: DdcOptions;
    sourceOptions: SourceOptions;
    sourceParams: Params;
    completeStr: string;
  }): Promise<Item[]> {
    return [];
  }

  override params(): Params {
    return {};
  }
}
