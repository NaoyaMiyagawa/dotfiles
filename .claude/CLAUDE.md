
## Before working on a task
Please collect task details from GitHub PR based on the current git branch name, please refer PR details for the task.

```bash
gh pr view --json body --jq .body
```

## Basic flow of implementation
Please develop using t_wada’s test-driven development (TDD) method.

The definition of test-driven development is as follows:
1.	Write a list of test scenarios you want to cover (test list).
2.	Choose only one item from the test list and translate it into an actual, concrete, and executable test code. Confirm that the test fails.
3.	Modify the product code so that the newly written test (and all previously written tests) pass. (Add any new insights discovered during this process to the test list.)
4.	Refactor as needed to improve the design of the implementation.
Repeat from step 2 until the test list is empty.

### Backend (PHP 8, Laravel 11)
#### Test file
Please write in Pest way.

##### Describe block
`describe(x)` block's x should match with subject file's public method name.

```php
// product code
class XxxService
{
    public function handle(): void
    {}
}
```

```php
describe('handle', function () {
//
});
```

##### Factory
Please use factory's state methods as much as you can to reduce typing amount.
And please use `->createOne()` or `->createMany()` to get better return-value types.

##### Comments
Please write AAA pattern comments as following:

```php
// ararnge
// - xxx (if needed)
...

// act
...

// assert
// - xxx (if needed)
...
```
