## Granite 34B

Currently there is an [opened issue in vLLM](https://github.com/vllm-project/vllm/issues/9844) that prevents to use Pipeline Parallelism with IBM Granite Models.
Due to that the IBM Granite models will not be loaded across multi-nodes by vLLM.