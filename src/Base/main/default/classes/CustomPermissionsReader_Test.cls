/**
 * Copyright (c), Andrew Fawcett
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice,
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice,
 *      this list of conditions and the following disclaimer in the documentation
 *      and/or other materials provided with the distribution.
 * - Neither the name of the Andrew Fawcett, nor the names of its contributors
 *      may be used to endorse or promote products derived from this software without
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 *  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 *  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 *  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 **/

@IsTest
private class CustomPermissionsReader_Test {
  /**
   * This will need to be modified to reflect a Custom Permission in the org,
   *   since DML in test code cannot create them :-(
   **/
  private static final String TEST_CUSTOM_PERMISSION;
  private static final User testUser;
  static {
    CustomPermission[] cps = [SELECT DeveloperName FROM CustomPermission WHERE NamespacePrefix = NULL];
    TEST_CUSTOM_PERMISSION = cps[0].DeveloperName;

    testUser = User_TestFactory.newUser('testFirst', 'testLast', 'Standard User');
    insert testUser;
  }

  @IsTest
  private static void testCustomPermissionAssigned() {
    System.runAs(testUser) {
      // Create PermissionSet with Custom Permission and asisgn to test user
      PermissionSet ps = new PermissionSet();
      ps.Name = 'CustomPermissionsReaderTest';
      ps.Label = 'CustomPermissionsReaderTest';
      insert ps;
      SetupEntityAccess sea = new SetupEntityAccess();
      sea.ParentId = ps.Id;
      sea.SetupEntityId = [SELECT Id FROM CustomPermission WHERE DeveloperName = :TEST_CUSTOM_PERMISSION][0].Id;
      insert sea;
      PermissionSetAssignment psa = new PermissionSetAssignment();
      psa.AssigneeId = testUser.Id;
      psa.PermissionSetId = ps.Id;
      insert psa;

      // Create reader
      //   Note: SObjectType for managed package developers should be a Custom Object from that package
      CustomPermissionsReader cpr = new CustomPermissionsReader(Account.SObjectType);

      // Assert the CustomPermissionsReader confirms custom permission assigned
      System.assertEquals(true, cpr.hasPermission(TEST_CUSTOM_PERMISSION));
    }
  }

  @IsTest
  private static void testCustomPermissionNotAssigned() {
    System.runAs(testUser) {
      // Assert the CustomPermissionsReader confirms custom permission not assigned
      System.assertEquals(
        false,
        new CustomPermissionsReader(Account.SObjectType).hasPermission(TEST_CUSTOM_PERMISSION)
      );
    }
  }

  @IsTest
  private static void testCustomPermissionNotValid() {
    try {
      // Assert the CustomPermissionsReader throws an exception for an invalid custom permission
      System.assertEquals(false, new CustomPermissionsReader(Account.SObjectType).hasPermission('NotValid'));
      System.assert(false, 'Expected an exception');
    } catch (Exception e) {
      System.assertEquals('Custom Permission NotValid is not valid.', e.getMessage());
    }
  }

  @IsTest
  private static void testCustomPermisionDefaultConstructor() {
    System.runAs(testUser) {
      // Assert the CustomPermissionsReader confirms custom permission not assigned
      System.assertEquals(false, new CustomPermissionsReader().hasPermission(TEST_CUSTOM_PERMISSION));
    }
  }
}
