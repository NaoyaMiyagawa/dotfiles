
## Before working on a task
Please collect task details from GitHub PR based on the current git branch name, please refer PR details for the task.

```bash
gh pr view --json title --jq .title
gh pr view --json body --jq .body
gh pr view --json comments --jq .comments
```

Our base branch for new feature is 'develop'.

## Basic flow of implementation
Please develop using t_wada’s test-driven development (TDD) method.

The definition of test-driven development is as follows:
1.	Write a list of test scenarios you want to cover (test list).
2.	Choose only one item from the test list and translate it into an actual, concrete, and executable test code. Confirm that the test fails.
3.	Modify the product code so that the newly written test (and all previously written tests) pass. (Add any new insights discovered during this process to the test list.)
4.	Refactor as needed to improve the design of the implementation.
Repeat from step 2 until the test list is empty.

### Backend (PHP 8, Laravel 11)
#### General
- Use `use` statement instead of FQN.
- Use `__invoke()` when invoking invokable class for better IDE support.


#### Test file
Please write in Pest way.

##### Command
Please run by this command.

```bash
./vendor/bin/sail test [filepath]
```

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
  it('stores xxx', function () {
    //...
  });

  describe('unhappy - validation', function () {
    //...
  });

  describe('unhappy - authentication', function () {
    //...
  });
});
```

##### BeforeEach
Please use variables first, then set to $this so make properties look simple,
unless the value to set to $this is static value which is not using factory.

```php
beforeEach(function () {
  /** @var User $user */
  $user = User::factory()->createOne();
  actingAs($user);

  $this->user = $user;
});
```

##### Dataset
When you can combine multiple test cases by using dataset `->with()`, you should do so.

Please always add line break to argument like this, so that it's easier to tell this test case uses dataset.
```php
    it('returns true when filename contains malicious strings', function (
      string $filename, // do not forget to add `,` anytime
    ) {
        // Arrange
        // - The filename is supplied via dataset

        // Act
        $result = FilenameSanitizer::containsMaliciousString($filename);

        // Assert
        expect($result)->toBeTrue();
    })->with([
        // if arguments are more than one, please use variable `$xxx =` in front of value so that it's easier to match which arg this value goes to
        'parent directory traversal' => ['../etc/passwd'],
        'double parent directory traversal' => ['../../etc/passwd'],
    ]);

```


##### Factory
Please use factory's state methods defined in each model factory as much as you
can to reduce manual-typing amount.
Please use `->forEachSequence()` when we want all data pattern.
Please use `->createOne()` or `->createMany()` to get better return-value types.
Please use `::factory(x)` instead of `->count(x)` to shorten line.

##### Comments
Please write AAA pattern comments following this. It can be combined like `// Act & Assert`
if the test case is compact enough.

```php
// Arrange
// - Set up ... (if needed. 'set up ...' is just for example)


// Act


// Assert
// - check ... (if needed. 'check ...' is just for example)
```

##### Pest functions
Please use by always importing to simplify test code.

```
use function Pest\Laravel\actingAs;
use function Pest\Laravel\mock;
```

##### BeforeEach
Please set `Event::fake([Xxx::class])` `Storage::fake('xx')` etc in `beforeEach`
when the endpoint or service class use those classes.

##### Feature test (= Controller test)
Please use `route('xxx')` to send requests.

Preferred to separate sending HTTP request and assertion like the following.

```php
// Act
$response = post(route(...))

// Assert
$response
  ->assertValid()
  ->assertRedirect();

... other data check
```

#### Static Analytics
##### Pint
Please run pint to format code so that I can commit without running pint manually.

```bash
vendor/bin/pint --dirty --parallel
```

##### PHPStan
Only runs when I asked for phpstan fixes because running phpstan would take a while.
Please use this command to run

```bash
# For entire app
./vendor/bin/sail exec app ./vendor/bin/phpstan

# For specific file
./vendor/bin/sail exec app ./vendor/bin/phpstan analyze {filepath}
```


## PR Code Review Fix
### How to get to know what to fix
When I ask you for code review fix, please look at the latest comments that are not resolved by this command:

```bash
gh pr view --json comments --jq .comments
gh api repos/:owner/:repo/pulls/$(gh pr view --json number --jq .number)/comments
```

Please ignore comments from `sonarqubecloud` as it's just a summary.
Please ignore comments start from `## Pull Request Overview` as it's just a summary.

### How to proceed the fix
I want to commit a fix for a comment one by one. Please list down fixes to do while working on it. And please wait for my approval to go next once you are done with 1 item so that I can commit.
