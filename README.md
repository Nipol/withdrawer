# Withdrawer

이는 해킹당한 Hot Wallet에서 ERC20을 출금하는데 도움을 줍니다. 여기에 제약 사항이 존재합니다. Contract에서 한 번에 처리할 수 있는 ERC20-Transfer에는 제한이 있기 때문에 이를 분배할 수 있는 기능이 포함되어 있습니다.

## 시나리오

1. Hot Wallet은 `WithdrawerMaker`를 긴급 상황일 때 토큰을 되돌릴 주소와 함께 배포되어 있어야 합니다.
    ```
    WithdrawerMaker#constructor(recipientAddress);
    ```

2. Hot Wallet이 취급하는 Token의 주소를 목록화 하여 Gas Limit이 허용하는 만큼 잘라 nonce로 관리한다.
    | nonce  | Token Address    |
    | ------ | ---------------- |
    |    0   | 0xabcedf...0000  |
    |        | 0xabcedf...0001  |
    |        | 0xabcedf...0002  |
    |        | 0xabcedf...0003  |
    |    1   | 0xabcedf...0004  |
    |        | 0xabcedf...0005  |
    |        | 0xabcedf...0006  |
    |        | 0xabcedf...0007  |
    |   ...  |  ...  |

3. `WithdrawerMaker`는 ERC20을 한 번에 전송하는 `Withdrawer`를 배포합니다. `Withdrawer`의 주소를 생성하는 값이 `nonce`와 `Token Address`의 합으로 이뤄지기 때문에 별도의 영역에서 관리되어야 합니다.

4. WithdrawerMaker가 Withdrawer를 배포하기 전에 주소를 알 수 있는 방법은 다음과 같습니다. 주소의 순서가 바뀌거나, nonce가 다르면 Withdrawer의 주소가 다릅니다.
    ```solidity
    /*
     * tokenAddresses = [0xabcedf...0000, 0xabcedf...0001, 0xabcedf...0002, 0xabcedf...0003];
     * nonce = 0;
     */
    address withdrawer = calculateAddress(tokenAddresses, nonce);
    ```

5. Hot Wallet은 문제가 생긴 경우, `Withdrawer`가 토큰을 한 번에 출금할 수 있도록 Token의 전송 권한을 위 과정을 통해 알게된 `Withdrawer` 주소에  Approve해 주어야 합니다.
    ```solidity
    // 아래를 Hot Wallet이 지원하는 Token 개수만큼 승인해 주어야 합니다.
    tokenAddress.approve(WithdrawerAddress, uint256(-1));
    ```

6. 해킹이 발생된 경우에, `WithdrawerMaker#deploy(tokenAddresses)`를 호출합니다. 자동으로 `Withdrawer` Contract를 배포하고, Hot Wallet에 있는 Token을 `WithdrawerMaker`를 배포할 때 설정했던 수신자로 이동시킵니다. `WithdrawerMaker`는 0에서 시작되여 내부적으로 nonce관리를 수행하며 외부에서 수정할 수 없도록 되어 있습니다. 따라서 2번 과정에서 테이블을 관리하는 것이 무척 중요합니다.

7. 새롭게 상장되는 Token이 있다면, 새로운 nonce와 Token Address가 한 쌍을 이루도록 Token을 관리하도록 하면 됩니다.

8. Withdrawer가 배포된 이후에 새로운 토큰 입금이 발견되었다면, `WithdrawerMaker#consumeWithOrder(nonce)`를 이용하여 해당 주소 영역에 해당하는 Token을 수신자가 수신할 수 있습니다.