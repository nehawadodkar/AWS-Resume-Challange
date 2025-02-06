import { DynamoDBClient, UpdateItemCommand } from '@aws-sdk/client-dynamodb';

// Create an instance of DynamoDBClient
const dynamoDBClient = new DynamoDBClient();

export const handler = async (event) => {
    //const tableName = 'VisitorCounter1';
    const tableName = process.env.dynamodb_table   // Get the variable
    const counterIDValue = '1';

    try {
        // Define the update parameters
        const params = {
            TableName: tableName,
            Key: {
                counterID: { S: counterIDValue } // Specify the partition key and its type
            },
            UpdateExpression: 'SET visitCount = if_not_exists(visitCount, :start) + :increment',
            ExpressionAttributeValues: {
                ':increment': { N: '1' },
                ':start': { N: '0' }
            },
            ReturnValues: 'UPDATED_NEW'
        };

        // Use the DynamoDB client to send an UpdateItemCommand
        const result = await dynamoDBClient.send(new UpdateItemCommand(params));

        return {
            statusCode: 200,
            body: JSON.stringify({
                message: 'Visit count updated successfully!',
                updatedVisitCount: result.Attributes?.visitCount?.N
            })
        };
    } catch (error) {
        console.error('Error updating visit count:', error);
        return {
            statusCode: 500,
            body: JSON.stringify({
                message: 'Failed to update visit count',
                error: error.message
            })
        };
    }
};